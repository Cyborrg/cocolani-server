// =====================================================
// admin.as  –  Cocolani administration extension
// =====================================================

var dbase;


var SEP  = String.fromCharCode(1);
var SEP2 = String.fromCharCode(2);



function init()
{
	dbase = _server.getDatabaseManager();
}

function destroy()
{
	delete dbase;
}



function handleRequest(cmd, params, user, fromRoom)
{
	trace("[admin] cmd=" + cmd + "  user=" + user.getName());

	var zone = _server.getCurrentZone();

	// Moderator-only access check 
	if (!user.isModerator())
	{
		trace("[admin] BLOCKED non-moderator " + user.getName() + " attempted: " + cmd);
		dbSaveUserField(user.getName(), "hacks", "True");
		_server.banUser(user, 1,
			"You attempted to access a restricted function. You have been banned.",
			_server.BAN_BY_NAME);
		return;
	}

	// ---------------------------------------------------------
	// brdcast  –  Broadcast a text message to the whole zone
	// Client sends: { cmd:"brdcast", ext:"admin", msg:"..." }
	// ---------------------------------------------------------
	if (cmd == "brdcast")
	{
		var msg = params.msg;
		if (msg == null || String(msg).length < 2) return;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "broadcast";
		resp.data = String(msg);
		_server.sendResponse(resp, -1, null, getAllPlayersInZone(zone));
	}

	// ---------------------------------------------------------
	// searchUsers  –  Return online user info for a name or "*"
	// Client sends: { cmd:"searchUsers", ext:"admin", nm:"..." }
	// Response per entry (SEP-delimited):
	//   username | roomID | IP | status_ID | hacks | about |
	//   register_date | userID | lastSwear | swear
	// ---------------------------------------------------------
	else if (cmd == "searchUsers")
	{
		var nameQuery  = String(params.nm);
		var usersArray = [];

		if (nameQuery == "*")
		{
			var rooms = zone.getRooms();
			for (var ri in rooms)
			{
				var roomUsers = rooms[ri].getAllUsers();
				for (var ui in roomUsers)
				{
					var u = roomUsers[ui];
					if (u.getName() == user.getName()) continue;
					var entry = buildUserInfoString(u);
					if (entry != null) usersArray.push(entry);
				}
			}
		}
		else
		{
			var tgt = getUserByName(nameQuery);
			if (tgt != null)
			{
				var entry = buildUserInfoString(tgt);
				if (entry != null) usersArray[0] = entry;
			}
		}

		var resp   = {};
		resp._cmd  = "adminFn";
		resp.sub   = "userList";
		resp.users = usersArray;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// quickIPBan  –  Insert an IP-only ban without an online target
	// Client sends: { cmd:"quickIPBan", ext:"admin", tgt:"x.x.x.x", exp:"reason" }
	// ---------------------------------------------------------
	else if (cmd == "quickIPBan")
	{
		var ip     = String(params.tgt);
		var reason = String(params.exp);

		if (!isValidIP(ip))
		{
			trace("[admin] BLOCKED invalid IP: " + ip);
			return;
		}

		var sql = "INSERT INTO `cc_bans` (`ip`, `username`, `reason`, `until`, `banned_by`, `ban_type`)"
		        + " VALUES ('" + dbEscape(ip) + "', '', '" + dbEscape(reason) + "', '" + dbEscape(getBanUntil()) + "', '"
		        + dbEscape(user.getName()) + "', 'ip')";
		dbase.executeCommand(sql);

		var d    = {};
		d.ip     = ip;
		d.ref    = user.getName();
		d.reason = reason;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "banIP";
		resp.data = d;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// msg  –  Display a pop-up notice to a specific player
	// Client sends: { cmd:"msg", ext:"admin", id:<userID>, exp:"text" }
	// ---------------------------------------------------------
	else if (cmd == "msg")
	{
		if (!isValidInt(params.id)) { trace("[admin] BLOCKED invalid id"); return; }

		var targetUser = _server.getUserById(Number(params.id));
		if (targetUser == null) return;

		var resp  = {};
		resp._cmd = "error";
		resp.err  = String(params.exp);
		_server.sendResponse(resp, -1, null, [targetUser]);
	}

	// ---------------------------------------------------------
	// modChat  –  Private moderator-to-player message
	// Client sends: { cmd:"modChat", ext:"admin", tgt:{nm:"..."}, txt:"..." }
	// ---------------------------------------------------------
	else if (cmd == "modChat")
	{
		var tgtObj = params.tgt;
		if (tgtObj == null) return;

		var targetUser = getUserByName(String(tgtObj.nm));
		if (targetUser == null) return;

		var senderInfo    = {};
		senderInfo.nm     = user.getName();
		senderInfo.id     = user.getUserId();

		var resp  = {};
		resp._cmd = "mod_response";
		resp.tgt  = senderInfo;
		resp.txt  = params.txt;
		_server.sendResponse(resp, -1, null, [targetUser]);
	}

	// ---------------------------------------------------------
	// ban  –  Permanent name ban (also records IP)
	// Client sends: { cmd:"ban", ext:"admin", id:<userID>, exp:"reason" }
	// ---------------------------------------------------------
	else if (cmd == "ban")
	{
		if (!isValidInt(params.id)) { trace("[admin] BLOCKED invalid id"); return; }

		var targetPlayer = _server.getUserById(Number(params.id));
		if (targetPlayer == null) return;

		var tgtName = targetPlayer.getName();
		var tgtIP   = targetPlayer.getIpAddress();
		var reason  = String(params.exp);

		var sql = "INSERT INTO `cc_bans` (`username`, `ip`, `reason`, `until`, `banned_by`, `ban_type`)"
		        + " VALUES ('" + dbEscape(tgtName) + "', '" + dbEscape(tgtIP) + "', '"
		        + dbEscape(reason) + "', '" + dbEscape(getBanUntil()) + "', '" + dbEscape(user.getName()) + "', 'name')";
		dbase.executeCommand(sql);

		_server.banUser(targetPlayer, 3, reason, _server.BAN_BY_NAME);

		var d    = {};
		d.tgt    = tgtName;
		d.ref    = user.getName();
		d.reason = reason;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "banned";
		resp.data = d;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// banIP  –  Permanent IP ban
	// Client sends: { cmd:"banIP", ext:"admin", id:<userID>, exp:"reason" }
	// ---------------------------------------------------------
	else if (cmd == "banIP")
	{
		if (!isValidInt(params.id)) { trace("[admin] BLOCKED invalid id"); return; }

		var targetPlayer = _server.getUserById(Number(params.id));
		if (targetPlayer == null) return;

		var tgtName = targetPlayer.getName();
		var tgtIP   = targetPlayer.getIpAddress();
		var reason  = String(params.exp);

		var sql = "INSERT INTO `cc_bans` (`ip`, `username`, `reason`, `until`, `banned_by`, `ban_type`)"
		        + " VALUES ('" + dbEscape(tgtIP) + "', '', '"
		        + dbEscape(reason) + "', '" + dbEscape(getBanUntil()) + "', '" + dbEscape(user.getName()) + "', 'ip')";
		dbase.executeCommand(sql);

		_server.banUser(targetPlayer, 3, reason, _server.BAN_BY_IP);

		var d    = {};
		d.tgt    = tgtName;
		d.ip     = tgtIP;
		d.ref    = user.getName();
		d.reason = reason;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "banIP";
		resp.data = d;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// kick  –  Disconnect a player with a reason
	// Client sends: { cmd:"kick", ext:"admin", id:<userID>, exp:"reason" }
	// ---------------------------------------------------------
	else if (cmd == "kick")
	{
		if (!isValidInt(params.id)) { trace("[admin] BLOCKED invalid id"); return; }

		var targetPlayer = _server.getUserById(Number(params.id));
		if (targetPlayer == null) return;

		var tgtName = targetPlayer.getName();
		var reason  = String(params.exp);

		_server.kickUser(targetPlayer, 3, reason);

		var d    = {};
		d.tgt    = tgtName;
		d.ref    = user.getName();
		d.reason = reason;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "kick";
		resp.data = d;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// ipsearchfield  –  Fetch session history rows by IP address
	// Client sends: { cmd:"ipsearchfield", ext:"admin", tgt:"x.x.x.x" }
	// Response: { sub:"userListIP", data:[{nm,ip,ss,se,zn}, ...] }
	// ---------------------------------------------------------
	else if (cmd == "ipsearchfield")
	{
		var ip = String(params.tgt);
		if (!isValidIP(ip))
		{
			trace("[admin] BLOCKED invalid IP: " + ip);
			return;
		}

		var sql  = "SELECT `username`, `IP`, `seisson_start`, `seisson_end`, `lastZone`"
		         + " FROM `cc_user` WHERE `IP` = '" + dbEscape(ip) + "'";
		var qRes = dbase.executeQuery(sql);

		var sessions = [];
		if (qRes != null)
		{
			for (var i = 0; i < qRes.size(); i++)
			{
				var row     = qRes.get(i);
				var session = {};
				session.nm  = row.getItem("username");
				session.ip  = row.getItem("IP");
				session.ss  = row.getItem("seisson_start");
				session.se  = row.getItem("seisson_end");
				session.zn  = row.getItem("lastZone");
				sessions.push(session);
			}
		}

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "userListIP";
		resp.data = sessions;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// getbanlist  –  Return all active bans split by type
	// Client expects: resp.data  = SEP-joined usernames
	//                 resp.ipban = SEP-joined IP addresses
	// ---------------------------------------------------------
	else if (cmd == "getbanlist")
	{
		// Name bans
		var sql1  = "SELECT `username` FROM `cc_bans`"
		          + " WHERE `username` != '' ORDER BY `username` ASC";
		var qRes1 = dbase.executeQuery(sql1);
		var nameList = "";
		if (qRes1 != null)
		{
			for (var i = 0; i < qRes1.size(); i++)
			{
				if (i > 0) nameList += SEP;
				nameList += qRes1.get(i).getItem("username");
			}
		}

		// IP-only bans
		var sql2  = "SELECT `ip` FROM `cc_bans`"
		          + " WHERE `username` = '' AND `ip` != '' ORDER BY `ip` ASC";
		var qRes2 = dbase.executeQuery(sql2);
		var ipList = "";
		if (qRes2 != null)
		{
			for (var j = 0; j < qRes2.size(); j++)
			{
				if (j > 0) ipList += SEP;
				ipList += qRes2.get(j).getItem("ip");
			}
		}

		var resp   = {};
		resp._cmd  = "adminFn";
		resp.sub   = "banList";
		resp.data  = nameList;
		resp.ipban = ipList;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// getModHistory  –  Ban record history for a name or IP
	// Client sends: { cmd:"getModHistory", ext:"admin", tgt:"...", type:"usr"|"ip" }
	// Response: { sub:"modHistory", data:"<SEP2-separated entries>" }
	// Each entry:  id SEP username SEP ip SEP ban_type SEP reason SEP ban_date
	// The client displays:
	//   "Mod ID:<id> <ban_type> user '<username>' on <date>,reason:<reason> target IP=<ip>"
	// ---------------------------------------------------------
	else if (cmd == "getModHistory")
	{
		var banType = String(params.type);
		var target  = dbEscape(params.tgt);

		var sql;
		if (banType == "usr")
			sql = "SELECT * FROM `cc_bans` WHERE `username` = '" + target + "' ORDER BY `id` DESC";
		else
			sql = "SELECT * FROM `cc_bans` WHERE `ip` = '" + target + "' ORDER BY `id` DESC";

		var qRes    = dbase.executeQuery(sql);
		var history = "";
		if (qRes != null)
		{
			for (var i = 0; i < qRes.size(); i++)
			{
				if (i > 0) history += SEP2;
				var row   = qRes.get(i);
				history  += row.getItem("id")        + SEP
				          + row.getItem("username")   + SEP
				          + row.getItem("ip")         + SEP
				          + row.getItem("ban_type")   + SEP
				          + row.getItem("reason")     + SEP
				          + row.getItem("ban_date");
			}
		}

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "modHistory";
		resp.data = history;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// unban  –  Remove an active name or IP ban
	// Client sends: { cmd:"unban", ext:"admin", tgt:"...", type:"usr"|"ip", reason:"..." }
	// ---------------------------------------------------------
	else if (cmd == "unban")
	{
		var banType = String(params.type);
		var target  = dbEscape(params.tgt);
		var reason  = String(params.reason);

		if (banType == "usr")
		{
			dbase.executeCommand(
				"DELETE FROM `cc_bans` WHERE `username` = '" + target + "'");
			_server.removeBanishment(String(params.tgt), _server.BAN_BY_NAME);
		}
		else
		{
			dbase.executeCommand(
				"DELETE FROM `cc_bans` WHERE `ip` = '" + target + "' AND `username` = ''");
			_server.removeBanishment(String(params.tgt), _server.BAN_BY_IP);
		}

		var d    = {};
		d.tgt    = String(params.tgt);
		d.ref    = user.getName();
		d.reason = reason;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "adminMsg";
		resp.type = "unban";
		resp.data = d;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// getChatHistory  –  Send the regular chat log to the monitor
	// Client sends: { cmd:"getChatHistory", ext:"admin" }
	// ---------------------------------------------------------
	else if (cmd == "getChatHistory")
	{
		sendChatHistory(user, "False", "chatHistory");
	}

	// ---------------------------------------------------------
	// getSwearHistory  –  Send the swear-flagged chat log
	// Client sends: { cmd:"getSwearHistory", ext:"admin" }
	// ---------------------------------------------------------
	else if (cmd == "getSwearHistory")
	{
		sendChatHistory(user, "True", "swearHistory");
	}

	// ---------------------------------------------------------
	// chatListen / swearListen
	// Sent by the client when the corresponding monitor panel is
	// closed.  No server-side subscription state is maintained;
	// acknowledged silently.
	// ---------------------------------------------------------
	else if (cmd == "chatListen" || cmd == "swearListen")
	{
		trace("[admin] " + user.getName() + " closed monitor: " + cmd);
	}

	// ---------------------------------------------------------
	// getOptions  –  Return server config and battle thresholds
	// Client sends: { cmd:"getOptions", ext:"admin" }
	// Response: { sub:"options", data:[{startGameThreshold}, ...], st:"true"|"false" }
	// ---------------------------------------------------------
	else if (cmd == "getOptions")
	{
		var btl0 = getBattleSetting("0");
		var btl1 = getBattleSetting("1");
		var btl  = [
			{startGameThreshold: (btl0 != null) ? Number(btl0.getItem("startGameThreshold")) : 2},
			{startGameThreshold: (btl1 != null) ? Number(btl1.getItem("startGameThreshold")) : 2}
		];

		var settingsRow = getDefSettingsRow();
		var accessOpen  = (settingsRow != null)
		                ? String(settingsRow.getItem("logins_open"))
		                : "true";

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "options";
		resp.data = btl;
		resp.st   = accessOpen;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// updateOptions  –  Save new battle game start thresholds
	// Client sends: { cmd:"updateOptions", ext:"admin", battledata:[...] }
	// ---------------------------------------------------------
	else if (cmd == "updateOptions")
	{
		var bData = params.battledata;
		if (bData != null && bData.length >= 2)
		{
			var t0 = Number(bData[0].startGameThreshold);
			var t1 = Number(bData[1].startGameThreshold);
			if (!isNaN(t0) && !isNaN(t1))
			{
				dbase.executeCommand(
					"UPDATE `cc_battle_settings` SET `startGameThreshold` = "
					+ t0 + " WHERE `room_id` = '0'");
				dbase.executeCommand(
					"UPDATE `cc_battle_settings` SET `startGameThreshold` = "
					+ t1 + " WHERE `room_id` = '1'");
			}
		}

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "options";
		resp.req  = "updatePlayersSucc";
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// setAccessStatus  –  Toggle whether new logins are permitted
	// Client sends: { cmd:"setAccessStatus", ext:"admin", st:<bool> }
	// ---------------------------------------------------------
	else if (cmd == "setAccessStatus")
	{
		var newStatus = dbEscape(String(params.st));
		dbase.executeCommand(
			"UPDATE `cc_def_settings` SET `logins_open` = '"
			+ newStatus + "' WHERE `id` = 1");
		var zonesActive = (newStatus == "true") ? "1" : "0";
		dbase.executeCommand(
			"UPDATE `cc_zones` SET `logins_active` = '" + zonesActive + "'");
		dbase.executeCommand(
			"UPDATE `cc_servers` SET `logins_active` = '" + zonesActive + "'");

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "options";
		resp.req  = "updateLogins";
		resp.st   = newStatus;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// restart  –  Warn every player then disconnect them all
	// Client sends: { cmd:"restart", ext:"admin", time:<mins>, warningInterval:<secs> }
	// ---------------------------------------------------------
	else if (cmd == "restart")
	{
		var minutes    = isValidInt(params.time) ? Number(params.time) : 0;
		var warningMsg = "The server is restarting in " + minutes
		               + " minute(s). You will be disconnected shortly.";
		var allPlayers = getAllPlayersInZone(zone);

		var warn  = {};
		warn._cmd = "error";
		warn.err  = warningMsg;
		_server.sendResponse(warn, -1, null, allPlayers);

		for (var pi in allPlayers)
		{
			_server.kickUser(allPlayers[pi], 3, warningMsg);
		}
	}

	// ---------------------------------------------------------
	// refrehSettings  –  Signal the server to re-read its config
	// ---------------------------------------------------------
	else if (cmd == "refrehSettings")
	{
		trace("[admin] refrehSettings requested by " + user.getName());
	}

	// ---------------------------------------------------------
	// getHomeAddr  –  Resolve a home room name to tribe + address
	// Used by admin_roomlist teleport-to-home feature.
	// Client sends: { cmd:"getHomeAddr", ext:"home"|"admin", id:"<roomName>" }
	// ---------------------------------------------------------
	else if (cmd == "getHomeAddr")
	{
		var roomName = String(params.id);
		var homeRoom = zone.getRoomByName(roomName);
		if (homeRoom == null) return;

		var resp  = {};
		resp._cmd = "adminFn";
		resp.sub  = "gotoHome";

		var parts = roomName.split("-");
		if (parts.length < 3) return;

		resp.tid  = Number(parts[1]);
		resp.hid  = Number(parts[2]);
		resp.hint = 1;

		_server.sendResponse(resp, -1, null, [user]);
	}

	else
	{
		trace("[admin] Unknown command: " + cmd);
	}
}

function handleInternalEvent(evt)
{
}

// =========================================================
// HELPERS
// =========================================================

// Build  user info string expected by admin_usersearch.
// Format: username|roomID|IP|status_ID|hacks|about|register_date|userID|lastSwear|swear
function buildUserInfoString(u)
{
	var uName  = u.getName();
	var rooms  = u.getRoomsConnected();
	var roomId = (rooms != null && rooms.length > 0) ? String(rooms[0]) : "0";
	var ip     = u.getIpAddress();

	var data = dbGetUserFields(uName,
		["status_ID", "hacks", "about", "register_date", "lastSwear", "swear"]);
	if (data == null) return null;

	return uName                 + SEP
	     + roomId                + SEP
	     + ip                    + SEP
	     + data["status_ID"]     + SEP
	     + data["hacks"]         + SEP
	     + data["about"]         + SEP
	     + data["register_date"] + SEP
	     + String(u.getUserId()) + SEP
	     + data["lastSwear"]     + SEP
	     + data["swear"];
}


function sendChatHistory(user, swearFlag, subName)
{
	var sql  = "SELECT `Sender`, `Room_ID`, `Time`, `Message`"
	         + " FROM `cc_chat` WHERE `Swear` = '" + dbEscape(swearFlag) + "'"
	         + " ORDER BY `Time` DESC LIMIT 200";
	var qRes = dbase.executeQuery(sql);

	var data = [];
	if (qRes != null)
	{
		for (var i = 0; i < qRes.size(); i++)
		{
			var row = qRes.get(i);
			data.push(
				row.getItem("Sender")  + SEP
			  + row.getItem("Room_ID") + SEP
			  + row.getItem("Time")    + SEP
			  + row.getItem("Message")
			);
		}
	}

	var resp  = {};
	resp._cmd = "adminFn";
	resp.sub  = subName;
	resp.data = data;
	_server.sendResponse(resp, -1, null, [user]);
}

// =========================================================
// DATABASE HELPERS
// =========================================================

function dbEscape(val)
{
	if (val == null || val == undefined) return "";
	return _server.escapeQuotes(String(val));
}


function dbGetUserFields(username, fields)
{
	var safe = [];
	for (var i = 0; i < fields.length; i++)
	{
		if (!isValidIdentifier(fields[i]))
		{
			trace("[admin/db] BLOCKED invalid column: " + fields[i]);
			return null;
		}
		safe.push("`" + fields[i] + "`");
	}
	var sql = "SELECT " + safe.join(", ")
	        + " FROM `cc_user` WHERE `username` = '" + dbEscape(username) + "'";
	var res = dbase.executeQuery(sql);
	if (res == null || res.size() == 0) return null;

	var row  = res.get(0);
	var data = {};
	for (var j = 0; j < fields.length; j++)
	{
		var v           = row.getItem(fields[j]);
		data[fields[j]] = (v != null) ? String(v) : "";
	}
	return data;
}

function dbSaveUserField(username, field, value)
{
	if (!isValidIdentifier(field))
	{
		trace("[admin/db] BLOCKED invalid field: " + field);
		return false;
	}
	var sql = "UPDATE `cc_user` SET `" + field + "` = '" + dbEscape(value) + "'"
	        + " WHERE `username` = '" + dbEscape(username) + "'";
	return dbase.executeCommand(sql);
}

function getDefSettingsRow()
{
	var res = dbase.executeQuery(
		"SELECT * FROM `cc_def_settings` WHERE `id` = 1");
	if (res == null || res.size() == 0) return null;
	return res.get(0);
}

function getBanUntil()
{
	var row = getDefSettingsRow();
	if (row == null) return "";
	var days = Number(row.getItem("ban_period_days"));
	if (isNaN(days) || days <= 0) return ""; // empty = permanent
	var until = new Date();
	until.setDate(until.getDate() + days);
	return until.getFullYear() + "-"
	     + ("0" + (until.getMonth() + 1)).slice(-2) + "-"
	     + ("0" + until.getDate()).slice(-2);
}

function getBattleSetting(roomId)
{
	var sql = "SELECT * FROM `cc_battle_settings` WHERE `room_id` = '"
	        + dbEscape(roomId) + "'";
	var res = dbase.executeQuery(sql);
	if (res == null || res.size() == 0) return null;
	return res.get(0);
}

// =========================================================
// VALIDATION HELPERS
// =========================================================

// true for integer values (positive, negative, or zero)
function isValidInt(val)
{
	if (val == null || val == undefined || val == "") return false;
	var n = Number(val);
	return !isNaN(n) && n == Math.floor(n);
}

// true for plausible IPv4 strings (digits and dots, 7–15 chars)
function isValidIP(ip)
{
	if (ip == null || ip == "") return false;
	var s = String(ip);
	if (s.length < 7 || s.length > 15) return false;
	for (var i = 0; i < s.length; i++)
	{
		var c = s.charAt(i);
		if (!((c >= "0" && c <= "9") || c == ".")) return false;
	}
	return true;
}


function isValidIdentifier(name)
{
	if (name == null || name == undefined || name == "") return false;
	var s = String(name);
	for (var i = 0; i < s.length; i++)
	{
		var c = s.charAt(i);
		if (!((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") ||
		      (c >= "0" && c <= "9") || c == "_"))
			return false;
	}
	return true;
}

// =========================================================
// ZONE / ROOM HELPERS
// =========================================================

function getUserByName(name)
{
	var zone  = _server.getCurrentZone();
	var rooms = zone.getRooms();
	for (var r in rooms)
	{
		var users = rooms[r].getAllUsers();
		for (var u in users)
		{
			if (users[u].getName() == name) return users[u];
		}
	}
	return null;
}

function getAllPlayersInZone(zone)
{
	var result = [];
	var rooms  = zone.getRooms();
	for (var r in rooms)
	{
		var users = rooms[r].getAllUsers();
		for (var u in users)
		{
			result.push(users[u]);
		}
	}
	return result;
}
