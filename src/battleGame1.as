/**
 * Battle Game Extension (battleGame1.as)
 * Zone-level extension for Cocolani battle system
 *
 * Handles the turn-based battle protocol game commands:
 *   ready, mv, result
 *
 * Initialization (loadLevelData, strtTimer, init) is handled by gamesRoom.as.
 * This extension manages the gameplay phase: ready > start > turn cycle -> endGame
 */

var dbase;
var battleRooms = {}; // keyed by roomId
var TURN_TIMER = 7; // seconds per turn for aiming/firing
var TURN_BUFFER = 0; // extra seconds not used for now
var turnCheckTimerId = null;

function init()
{
	dbase = _server.getDatabaseManager();
	// Start turn timer poller (checks every 1 second)
	turnCheckTimerId = setInterval("checkTurnTimers", 1000);
	trace("[BattleGame] Extension loaded, turn timer poller started");

}

function destroy()
{
	if (turnCheckTimerId != null)
		clearInterval(turnCheckTimerId);
	delete dbase;

}

/**
 * Polling function: checks if any battle's turn timer has expired
 */
function checkTurnTimers()
{
	var now = (new Date()).getTime();
	for (var roomId in battleRooms)
	{
		var battle = battleRooms[roomId];

		// Check turn timer: waiting for turn timer to expire during gameplay
		if (battle.waitingForTurn && battle.state == "PLAYING")
		{
			if (now - battle.turnStartTime >= (TURN_TIMER + TURN_BUFFER) * 1000)
			{
				battle.waitingForTurn = false;

				trace("[BattleGame] Turn timer expired for room " + roomId);

				startTurn(battle);

			}
		}
	}
}

function handleRequest(cmd, params, user, fromRoom)
{
	trace("[BattleGame] cmd=" + cmd + " from " + user.getName() + " in room " + fromRoom);

	// Lazily initialize battle state for this room on first command
	if (battleRooms[fromRoom] == undefined)
	{
		initBattleState(fromRoom);

	}

	var battle = battleRooms[fromRoom];

	if (battle == null)
		return;

	var pid = user.getPlayerIndex();

	if (cmd == "ready")
	{
		handleReady(battle, pid, user);

	}
	else if (cmd == "mv")
	{
		handleMove(battle, pid, params);

	}
	else if (cmd == "result")
	{
		handleResultData(battle, pid, params);

	}
}

function handleInternalEvent(evt)
{
	var evtName = evt.name;

	if (evtName == "userExit" || evtName == "userLost")
	{
		for (var roomId in battleRooms)
		{
			var battle = battleRooms[roomId];

			if (battle == null)
				continue;

			for (var pid in battle.players)
			{
				var p = battle.players[pid];

				if (p.user != undefined)
				{
					try
					{
						var uId = evt["userId"];

						if (p.user.getUserId() == uId)
						{
							trace("[BattleGame] Player " + pid + " left battle room " + roomId);

							delete battle.players[pid];

							battle.numPlayers--;

							if (battle.state == "PLAYING" && battle.numPlayers <= 1)
							{
								endBattle(battle);

							}
							if (battle.numPlayers <= 0)
							{
								trace("[BattleGame] Removing empty battle " + roomId);

								delete battleRooms[roomId];

							}
							return;

						}
					}
					catch (e)
					{
					}
				}
			}
		}
	}
}


function initBattleState(roomId)
{
	var zone = _server.getCurrentZone();

	var room = zone.getRoom(roomId);

	if (room == null)
	{
		trace("[BattleGame] Cannot find room " + roomId);

		return;

	}

	trace("[BattleGame] Initializing battle state for room " + roomId + " (" + room.getName() + ")");

	var battle = {
			roomId: roomId,
			room: room,
			state: "LOADING",
			players: {},
			numPlayers: 0,
			movesReceived: 0,
			resultsReceived: 0,
			turnCount: 0,
			waitingForTurn: false,
			turnStartTime: 0,
			createdTime: (new Date()).getTime(),
			allReadyWaiting: false,
			initSent: false
		};

	var userList = room.getAllUsers();

	for (var i = 0; i < userList.length; i++)
	{
		var u = userList[i];

		var pid = u.getPlayerIndex();

		if (pid <= 0)
			continue;

		var tribe = 1;

		try
		{
			var trbVar = u.getVariable("trb");

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
			var sql = "SELECT * FROM cc_user WHERE username='" + u.getName() + "'";

			var queryRes = dbase.executeQuery(sql);

			if (queryRes != null && queryRes.size() > 0)
			{
				var row = queryRes.get (0);
				// Use skill column for XP (skill stores "xp1,xp2")
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

					if (btlParts.length > 1)
					{
						var totalBattles = Number(btlParts[1]);

						str = 5 + Math.floor(totalBattles / 10);

						hp = 100 + str;

					}
				}
			}
		}
		catch (e)
		{
			trace("[BattleGame] Error getting stats for " + u.getName() + ": " + e);

		}

		battle.players[pid] = {
				user: u,
				pid: pid,
				hp: hp,
				maxHp: hp,
				xp: xp,
				str: str,
				x: 456,
				y: 195,
				rot: 0,
				tribe: tribe,
				name: u.getName(),
				ready: false,
				moveData: null,
				resultData: null,
				totalDmg: 0
			};

		battle.numPlayers++;

		trace("[BattleGame] Added player " + pid + ": " + u.getName() + " tribe=" + tribe + " hp=" + hp);

	}

	battleRooms[roomId] = battle;

}

// ==================== GAME FLOW ====================

function handleReady(battle, pid, user)
{
	if (battle.players[pid] == undefined)
	{
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

		battle.players[pid] = {
				user: user,
				pid: pid,
				hp: 100,
				maxHp: 100,
				xp: 0,
				str: 5,
				x: 456,
				y: 195,
				rot: 0,
				tribe: tribe,
				name: user.getName(),
				ready: false,
				moveData: null,
				resultData: null,
				totalDmg: 0
			};

		battle.numPlayers++;

	}

	battle.players[pid].ready = true;

	var userList = battle.room.getAllUsers();

	var readyRes = [];

	readyRes[0] = "isReady";

	readyRes.push(String(pid));

	_server.sendResponse(readyRes, -1, null, userList, "str");

	trace("[BattleGame] Player " + pid + " is ready");

	// Check if all players ready
	var allReady = true;

	for (var p in battle.players)
	{
		if (!battle.players[p].ready)
		{
			allReady = false;

			break;

		}
	}

	if (allReady && battle.state == "LOADING")
	{
		// Start immediately when all ready
		// Countdown timing is handled by gamesRoom.as (delays loadLevelData+init)
		trace("[BattleGame] All players ready - starting game");

		startPlaying(battle);

	}
}

function startPlaying(battle)
{
	battle.state = "PLAYING";

	battle.turnCount = 0;

	var userList = battle.room.getAllUsers();

	var startRes = [];

	startRes[0] = "start";

	startRes.push(String(TURN_TIMER));

	_server.sendResponse(startRes, -1, null, userList, "str");

	trace("[BattleGame] Battle started in room " + battle.roomId);


	battle.waitingForTurn = true;

	battle.turnStartTime = (new Date()).getTime();

}

/**
 * Send getResult to request moves from all players
 */
function startTurn(battle)
{
	battle.turnCount++;

	battle.movesReceived = 0;

	battle.resultsReceived = 0;

	for (var pid in battle.players)
	{
		battle.players[pid].moveData = null;

		battle.players[pid].resultData = null;

	}

	var userList = battle.room.getAllUsers();

	var getResultRes = [];

	getResultRes[0] = "getResult";

	_server.sendResponse(getResultRes, -1, null, userList, "str");

	trace("[BattleGame] Turn " + battle.turnCount + " - getResult sent");

}

function handleMove(battle, pid, params)
{
	if (battle.players[pid] == undefined || battle.state != "PLAYING")
		return;

	battle.players[pid].moveData = params.mv;

	battle.movesReceived++;

	trace("[BattleGame] Move from pid=" + pid + " (" + battle.movesReceived + "/" + countAlivePlayers(battle) + ")");

	if (battle.movesReceived >= countAlivePlayers(battle))
	{
		broadcastRslt(battle);

	}
}

function broadcastRslt(battle)
{
	var rsltData = "";

	var isFirst = true;

	for (var pid in battle.players)
	{
		var p = battle.players[pid];

		if (!isFirst)
			rsltData += "|";

		isFirst = false;

		rsltData += "[" + p.pid + "]";

		rsltData += (p.moveData != null) ? p.moveData : "[]";

	}

	var userList = battle.room.getAllUsers();

	var rsltRes = [];

	rsltRes[0] = "rslt";

	rsltRes.push(rsltData);

	_server.sendResponse(rsltRes, -1, null, userList, "str");

	trace("[BattleGame] Broadcast rslt");

}

function handleResultData(battle, pid, params)
{
	if (battle.players[pid] == undefined || battle.state != "PLAYING")
		return;

	battle.players[pid].resultData = params.data;

	battle.resultsReceived++;

	trace("[BattleGame] Result from pid=" + pid + " (" + battle.resultsReceived + "/" + countAlivePlayers(battle) + ")");

	if (battle.resultsReceived >= countAlivePlayers(battle))
	{
		processResults(battle);

	}
}

function processResults(battle)
{
	var authorityResult = null;

	for (var pid in battle.players)
	{
		if (battle.players[pid].resultData != null)
		{
			authorityResult = battle.players[pid].resultData;

			break;

		}
	}

	if (authorityResult != null)
	{
		var playerResults = authorityResult.split("|");

		for (var i = 0; i < playerResults.length; i++)
		{
			var parts = playerResults[i].split(",");

			if (parts.length < 8)
				continue;

			var resPid = Number(parts[0]);

			if (battle.players[resPid] == undefined)
				continue;

			var dmgLost = Number(parts[1]);

			var newX = Number(parts[5]);

			var newY = Number(parts[6]);

			var newRot = Number(parts[7]);

			battle.players[resPid].hp -= dmgLost;

			if (battle.players[resPid].hp < 0)
				battle.players[resPid].hp = 0;

			battle.players[resPid].x = newX;

			battle.players[resPid].y = newY;

			battle.players[resPid].rot = newRot;

			battle.players[resPid].totalDmg += Number(parts[4]);

			battle.players[resPid].xp += Number(parts[4]);

		}
	}

	// Check for game end
	var tribe1Alive = 0;

	var tribe2Alive = 0;

	for (var pid in battle.players)
	{
		if (battle.players[pid].hp > 0)
		{
			if (battle.players[pid].tribe == 1)
				tribe1Alive++;

			else
				tribe2Alive++;

		}
	}

	if (tribe1Alive == 0 || tribe2Alive == 0)
	{
		var winnerTribe = (tribe1Alive > 0) ? "Yeknom" : "Huhuloa";

		endBattle(battle, winnerTribe);

		return;

	}

	broadcastNextMove(battle);

	battle.waitingForTurn = true;

	battle.turnStartTime = (new Date()).getTime();

}

function broadcastNextMove(battle)
{
	var nextmvData = "";

	var isFirst = true;

	for (var pid in battle.players)
	{
		var p = battle.players[pid];

		if (!isFirst)
			nextmvData += "|";

		isFirst = false;

		nextmvData += p.pid + "," + p.hp + "," + p.xp + ",";

		nextmvData += p.x + "," + p.y + "," + p.rot + ",";

		nextmvData += "undefined,0," + p.totalDmg + "," + p.totalDmg;

	}

	var userList = battle.room.getAllUsers();

	var nextmvRes = [];

	nextmvRes[0] = "nextmv";

	nextmvRes.push(String(TURN_TIMER));

	nextmvRes.push(nextmvData);

	_server.sendResponse(nextmvRes, -1, null, userList, "str");

	trace("[BattleGame] Broadcast nextmv");

}

function endBattle(battle, winnerTribe)
{
	if (battle.state == "ENDED")
		return;

	battle.state = "ENDED";

	battle.waitingForTurn = false;

	if (winnerTribe == undefined)
	{
		var tribe1Hp = 0;

		var tribe2Hp = 0;

		for (var pid in battle.players)
		{
			if (battle.players[pid].tribe == 1)
				tribe1Hp += battle.players[pid].hp;

			else
				tribe2Hp += battle.players[pid].hp;

		}
		winnerTribe = (tribe1Hp >= tribe2Hp) ? "Yeknom" : "Huhuloa";

	}

	// Increment cc_tribes battles_won for winner
	try
	{
		var winTId = (winnerTribe == "Yeknom") ? 1 : 2;
		dbase.executeCommand("UPDATE cc_tribes SET battles_won = battles_won + 1 WHERE ID = " + winTId);

		// Refresh "Battle Zone1" variables
		var lobby = _server.getCurrentZone().getRoomByName("Battle Zone1");

		if (lobby != null)
		{
			var t1Wins = 0;

			var t2Wins = 0;

			var qrWins = dbase.executeQuery("SELECT ID, battles_won FROM cc_tribes WHERE ID IN (1, 2)");

			if (qrWins != null)
			{
				for (var i = 0; i < qrWins.size(); i++)
				{
					var rowW = qrWins.get (i);

					var tid = Number(rowW.getItem("ID"));

					var bwon = Number(rowW.getItem("battles_won"));

					if (tid == 1)
						t1Wins = bwon;

					else if (tid == 2)
						t2Wins = bwon;

				}
			}
			var rVars = [
					{name: "tribe1WinsTdy", val: t1Wins},
					{name: "tribe2WinsTdy", val: t2Wins}
				];

			_server.setRoomVariables(lobby, null, rVars);

		}
	}
	catch (e)
	{
		trace("[BattleGame] Error updating cc_tribes or lobby: " + e);

	}

	var userList = battle.room.getAllUsers();

	var endRes = [];

	endRes[0] = "endGame";

	endRes.push(winnerTribe);

	_server.sendResponse(endRes, -1, null, userList, "str");

	for (var pid in battle.players)
	{
		var p = battle.players[pid];

		try
		{
			var sql = "SELECT btl, skill, lvl FROM cc_user WHERE username='" + p.name + "'";

			var queryRes = dbase.executeQuery(sql);

			if (queryRes != null && queryRes.size() > 0)
			{
				var row = queryRes.get (0);

				var btlStr = row.getItem("btl");

				var wins = 0;

				var total = 0;

				if (btlStr != null && btlStr != "")
				{
					var btlParts = String(btlStr).split(";");

					if (btlParts.length >= 2)
					{
						wins = Number(btlParts[0]);

						total = Number(btlParts[1]);

					}
				}
				total++;

				if ((p.tribe == 1 && winnerTribe == "Yeknom") ||
						(p.tribe == 2 && winnerTribe == "Huhuloa"))
				{
					wins++;

				}
				var newBtl = wins + ";" + total;

				// Update skill (XP) column: skill stores "xp1,xp2"
				// skill[0] is the player's total XP used by the client for level display
				var skillStr = row.getItem("skill");

				var skillParts = (skillStr != null && skillStr != "") ? String(skillStr).split(",") : ["0", "0"];

				var currentXP = Number(skillParts[0]);

				var currentXP2 = (skillParts.length > 1) ? Number(skillParts[1]) : 0;

				var earnedXP = p.totalDmg;

				var newXP = currentXP + earnedXP;

				var newSkill = newXP + "," + (currentXP2 + earnedXP);

				// Ensure lvl (level thresholds) is populated
				var lvlStr = row.getItem("lvl");

				var lvlUpdate = "";

				if (lvlStr == null || lvlStr == "")
				{
					lvlUpdate = ", lvl='20,50,100,300,800,1800,3000,4400,6000,7800,9800,12000,14400,17000'";

				}

				dbase.executeCommand("UPDATE cc_user SET btl='" + newBtl + "', skill='" + newSkill + "'" + lvlUpdate + " WHERE username='" + p.name + "'");

				trace("[BattleGame] Updated " + p.name + ": btl=" + newBtl + " skill=" + newSkill);

				var varUpd = {};

				varUpd._cmd = "VarUpd";

				varUpd.btl = newBtl;

				varUpd.skill = newSkill;

				_server.sendResponse(varUpd, -1, null, [p.user]);

			}
		}
		catch (e)
		{
			trace("[BattleGame] Error updating btl stats: " + e);

		}
	}

	trace("[BattleGame] Battle ended. Winner: " + winnerTribe);

	delete battleRooms[battle.roomId];

}

// ==================== HELPERS ====================

function countAlivePlayers(battle)
{
	var count = 0;

	for (var pid in battle.players)
	{
		if (battle.players[pid].hp > 0)
			count++;

	}
	return count;

}
