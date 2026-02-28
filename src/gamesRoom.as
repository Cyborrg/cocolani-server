/**
=====================================
 * Games Room Extension (gamesRoom.as)
 * Room-level extension for Room 10 (GamesRoom / Battle Zone)
 * Also registered as zone-level to enable request routing.
 *
 * Handles joingame: creates dynamic battle game rooms, joins players.
//=====================================
*/

var dbase;
var battleCounter = 0;
var battleRoomsState = {}; // keyed by roomId
var LOBBY_WAIT_SECONDS = 30;
var lobbyCheckTimerId = null;
var startThreshold = 2; // minimum players to start – loaded from cc_battle_settings

function init()
{
	dbase = _server.getDatabaseManager();
	lobbyCheckTimerId = setInterval("checkLobbyTimers", 2000);
	try
	{
		var qThr = dbase.executeQuery("SELECT `startGameThreshold` FROM `cc_battle_settings` WHERE `room_id` = '0'");
		if (qThr != null && qThr.size() > 0)
			startThreshold = Number(qThr.get(0).getItem("startGameThreshold"));
		if (isNaN(startThreshold) || startThreshold < 2) startThreshold = 2;
	}
	catch (e)
	{
		trace("[GamesRoom] Could not load startGameThreshold, using default 2");
	}
	trace("[GamesRoom] Extension loaded, lobby poller started, startThreshold=" + startThreshold);

}

function destroy()
{
	if (lobbyCheckTimerId != null)
		clearInterval(lobbyCheckTimerId);
	delete dbase;

}

/**
 * Polling function: checks if any lobby timer has expired
 * This handles the case where we wait for more players before starting
 */
function checkLobbyTimers()
{
	var now = (new Date()).getTime();
	for (var roomId in battleRoomsState)
	{
		var state = battleRoomsState[roomId];

		if (state.waitingForMore && !state.started)
		{
			var elapsed = now - state.firstJoinTime;

			if (elapsed >= LOBBY_WAIT_SECONDS * 1000)
			{
				trace("[GamesRoom] Lobby timer expired for room " + roomId + " - starting with " + state.playerCount + " players");
				startBattleLoading(state);

			}
		}

		if (state.started && state.loadingSent == false)
		{
			var cdElapsed = now - state.countdownStartTime;

			if (cdElapsed >= 30000)
			{
				trace("[GamesRoom] Countdown finished for room " + roomId + " - sending loadLevelData+init");

				sendBattleLoadData(state);

			}
		}
	}
}

function handleRequest(cmd, params, user, fromRoom)
{
	trace("[GamesRoom] cmd received: " + cmd);

	if (cmd == "joingame")
	{
		handleJoinGame(params, user, fromRoom);

	}
	else if (cmd == "leavegame")
	{
		trace("[GamesRoom] Player " + user.getName() + " leaving game");

	}
}

function handleInternalEvent(evt)
{

}

/**
 * Handle joingame: find or create battle room, join player
 */
function handleJoinGame(params, user, fromRoom)
{
	var zone = _server.getCurrentZone();

	var existingRoom = null;

	var existingRoomId = null;

	var rooms = zone.getRooms();

	for (var i = 0; i < rooms.length; i++)
	{
		var rm = rooms[i];

		var rmName = rm.getName();

		if (rmName.indexOf("Battle1_") == 0)
		{
			var rmId = rm.getId();

			var state = battleRoomsState[rmId];

			if (rm.howManyUsers() < rm.getMaxUsers() && (state == undefined || !state.started))
			{
				existingRoom = rm;

				existingRoomId = rmId;

				break;

			}
		}
	}

	if (existingRoom != null)
	{
		trace("[GamesRoom] Joining existing room: " + existingRoom.getName() + " id=" + existingRoomId);

		_server.joinRoom(user, fromRoom, false, existingRoomId, "", false, true);

		trackPlayer(existingRoomId, existingRoom, user);

	}
	else
	{
		battleCounter++;

		var roomName = "Battle1_" + battleCounter;

		var roomObj = {};

		roomObj.name = roomName;

		roomObj.maxU = 6;

		roomObj.maxS = 6;

		roomObj.isGame = true;

		roomObj.isTemp = true;

		var roomVars = [
				{name: "tb", val: "0"},
				{name: "plyrs", val: "8"}
			];

		trace("[GamesRoom] Creating battle room: " + roomName);

		var newRoom = _server.createRoom(roomObj, null, true, true, roomVars);

		if (newRoom != null)
		{
			var newRoomId = newRoom.getId();

			trace("[GamesRoom] Battle room created with ID: " + newRoomId);

			_server.joinRoom(user, fromRoom, false, newRoomId, "", false, true);

			trackPlayer(newRoomId, newRoom, user);

		}
		else
		{
			trace("[GamesRoom] ERROR: Failed to create battle room!");

		}
	}
}

/**
 * Track a player joining a battle room.
 * When 2+ players join, immediately send loadLevelData + strtTimer + init.
 */
function trackPlayer(roomId, room, user)
{
	if (battleRoomsState[roomId] == undefined)
	{
		battleRoomsState[roomId] = {
				room: room,
				roomId: roomId,
				playerCount: 0,
				started: false,
				waitingForMore: false,
				firstJoinTime: 0,
				level: 0,
				players: {}
			};

	}

	var state = battleRoomsState[roomId];

	var pid = user.getPlayerIndex();

	trace("[GamesRoom] trackPlayer: " + user.getName() + " pid=" + pid + " room=" + roomId + " count=" + (state.playerCount + 1));

	// Get player tribe
	var tribe = 1;

	try
	{
		var trbVar = user.getVariable("trb");

		if (trbVar != null)
			tribe = Number(trbVar.getValue());

	}
	catch (e)
	{
	}

	var xp = 0;

	var str = 5;

	var hp = 100;

	try
	{
		var sql = "SELECT * FROM cc_user WHERE username='" + user.getName() + "'";

		var queryRes = dbase.executeQuery(sql);

		if (queryRes != null && queryRes.size() > 0)
		{
			var row = queryRes.get (0);

			//  XP (skill stores "xp1,xp2")
			var skillData = row.getItem("skill");

			if (skillData != null && skillData != "")
			{
				var skillParts = String(skillData).split(",");

				xp = Number(skillParts[0]);

			}
			var btlData = row.getItem("btl");

			if (btlData != null && btlData != "")
			{
				var btlParts = String(btlData).split(";");

				var totalBattles = 0;

				if (btlParts.length > 1)
					totalBattles = Number(btlParts[1]);

				str = 5 + Math.floor(totalBattles / 10);

				hp = 100 + str;

			}
		}
	}
	catch (e)
	{
		trace("[GamesRoom] Error getting player data: " + e);

	}

	state.players[pid] = {
			user: user,
			pid: pid,
			hp: hp,
			xp: xp,
			str: str,
			tribe: tribe,
			name: user.getName()
		};

	state.playerCount++;

	if (state.playerCount == 1)
	{
		state.firstJoinTime = (new Date()).getTime();

	}

	try
	{
		var qThr = dbase.executeQuery("SELECT `startGameThreshold` FROM `cc_battle_settings` WHERE `room_id` = '0'");
		if (qThr != null && qThr.size() > 0)
		{
			var thr = Number(qThr.get(0).getItem("startGameThreshold"));
			if (!isNaN(thr) && thr >= 2) startThreshold = thr;
		}
	}
	catch (e) {}

	if (state.playerCount >= startThreshold && !state.started)
	{
		startBattleLoading(state);

	}
	else if (state.playerCount >= 6 && !state.started)
	{
		startBattleLoading(state);

	}
}

/**
 * Send all loading messages to all players in the battle room simultaneously.
 */
function startBattleLoading(state)
{
	if (state.started)
		return;

	state.started = true;
	// Battle map levels
	var availableLevels = [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12];

	state.level = availableLevels[Math.floor(Math.random() * availableLevels.length)];

	var userList = state.room.getAllUsers();

	trace("[GamesRoom] Starting countdown in room " + state.roomId + " level=" + state.level + " players=" + userList.length);

	var timerRes = [];

	timerRes[0] = "strtTimer";

	timerRes.push("300.0");

	_server.sendResponse(timerRes, -1, null, userList, "str");

	trace("[GamesRoom] Sent strtTimer: 300.0");

	state.countdownStartTime = (new Date()).getTime();

	state.loadingSent = false;

	var initData = "";

	var firstTribe = 1;

	var isFirst = true;

	for (var pid in state.players)
	{
		var p = state.players[pid];

		if (isFirst)
		{
			firstTribe = p.tribe;

			isFirst = false;

		}
		else
		{
			initData += ";";

		}
		initData += p.pid + ":" + p.xp + ":" + p.str + ":" + p.hp;

	}
	state.initData = initData;

	state.initTribe = firstTribe;

	trace("[GamesRoom] Countdown started, loadLevelData+init will be sent in ~25s");

}

/**
 * Send the delayed loadLevelData and init messages
 * Called by checkLobbyTimers after 25 seconds of countdown
 */
function sendBattleLoadData(state)
{
	state.loadingSent = true;

	var userList = state.room.getAllUsers();

	var res = [];

	res[0] = "loadLevelData";

	res.push(state.level + ".0");

	_server.sendResponse(res, -1, null, userList, "str");

	trace("[GamesRoom] Sent loadLevelData: " + state.level + ".0");

	var initRes = [];

	initRes[0] = "init";

	initRes.push(String(state.level));

	initRes.push(String(state.initTribe));

	initRes.push(state.initData);

	_server.sendResponse(initRes, -1, null, userList, "str");

	trace("[GamesRoom] Sent init: level=" + state.level + " tribe=" + state.initTribe + " data=" + state.initData);

}