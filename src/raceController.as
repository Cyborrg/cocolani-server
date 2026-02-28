// =============================================================
// raceController.as
// Room-level extension for the leisure tube ride.
// Registered on: Jungle Swimming, Volcano Leisure
//
// =============================================================


// seatMap[roomId][seatId] = sfsUserId
var seatMap = {};

// Maximum valid seat index for leisure tube objects (tube1 – tube3)
var MAX_TUBE_SEATS = 3;


function init()
{
	trace("[raceController] Extension loaded");
}

function destroy()
{
	delete seatMap;
}



function handleRequest(cmd, params, user, fromRoom)
{
	trace("[raceController] cmd=" + cmd + " user=" + user.getName() + " room=" + fromRoom);

	if (cmd == "sit")
	{
		cmdSit(params, user, fromRoom);
	}
	else if (cmd == "stand")
	{
		cmdStand(user, fromRoom);
	}
}



function handleInternalEvent(evt)
{
	if (evt.name == "userLost" || evt.name == "logOut")
	{
		releaseSeatForUser(evt.user, -1);
	}
	else if (evt.name == "userLeft")
	{
		releaseSeatForUser(evt.user, evt.fromRoom);
	}
}

// =============================================================
// cmdSit  –  Attempt to seat the player on a tube
// =============================================================

function cmdSit(params, user, fromRoom)
{
	var seatId = Number(params.id);

	if (isNaN(seatId) || seatId < 1 || seatId > MAX_TUBE_SEATS)
	{
		trace("[raceController] BLOCKED invalid seatId=" + seatId + " from " + user.getName());
		sendSitError(user);
		return;
	}

	if (seatMap[fromRoom] == undefined) seatMap[fromRoom] = {};

	if (seatMap[fromRoom][seatId] != undefined)
	{
		trace("[raceController] Seat " + seatId + " in room " + fromRoom + " already occupied");
		sendSitError(user);
		return;
	}

	var userId = user.getUserId();
	for (var s in seatMap[fromRoom])
	{
		if (seatMap[fromRoom][s] == userId)
		{
			trace("[raceController] " + user.getName() + " releasing stale seat " + s + " in room " + fromRoom);
			delete seatMap[fromRoom][s];
			break;
		}
	}

	seatMap[fromRoom][seatId] = userId;


	var uVars   = {};
	uVars.stob  = seatId;
	uVars.stsid = -1;
	_server.setUserVariables(user, uVars, true);

	trace("[raceController] " + user.getName() + " seated on tube " + seatId + " in room " + fromRoom);
}



function cmdStand(user, fromRoom)
{
	releaseSeatForUser(user, fromRoom);

	var uVars   = {};
	uVars.stob  = undefined;
	uVars.stsid = undefined;
	_server.setUserVariables(user, uVars, true);

	trace("[raceController] " + user.getName() + " stood from tube in room " + fromRoom);
}



function releaseSeatForUser(user, fromRoom)
{
	var userId = user.getUserId();

	if (fromRoom != undefined && fromRoom != -1)
	{
		if (seatMap[fromRoom] == undefined) return;

		for (var s in seatMap[fromRoom])
		{
			if (seatMap[fromRoom][s] == userId)
			{
				trace("[raceController] Released seat " + s + " in room " + fromRoom + " for " + user.getName());
				delete seatMap[fromRoom][s];
				return;
			}
		}
		return;
	}

	for (var roomId in seatMap)
	{
		for (var s in seatMap[roomId])
		{
			if (seatMap[roomId][s] == userId)
			{
				trace("[raceController] Released seat " + s + " in room " + roomId + " for " + user.getName());
				delete seatMap[roomId][s];
				return;
			}
		}
	}
}



function sendSitError(user)
{
	var resp  = {};
	resp._cmd = "sceneRep";
	resp.sub  = "sit";
	resp.err  = 1;
	_server.sendResponse(resp, -1, null, [user], "xml");
}
