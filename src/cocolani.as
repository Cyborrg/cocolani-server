// =============================================================
// cocolani.as
// Core zone extension: login, room init, events, chat moderation
// =============================================================

// Client auth: MD5( secretKey + salt + storedPassword )
// getPristine() decodes "dpsBtbcsOJso5oWRZvEy" by char-1 = "corAsabrNIrn4nVQYuDx"
var salt = "corAsabrNIrn4nVQYuDx";


function init()
{
	trace("|===========================================|");
	trace("|   		COCOLANI SERVER STARTED 	       |");
	trace("|        	  @ CYBORG                     |");
	trace("|===========================================|");

	var zone = _server.getCurrentZone();
	zone.setPubMsgInternalEvent(true);
	zone.setPrivMsgInternalEvent(true);

	// Room Variables (tb = Tribe ID) 
	// Load tribe assignments from config.xml
	var rooms    = zone.getRooms();
	var tribeMap = {};

	try
	{
		var cfgContent = _server.readFile("config.xml");
		var cfgXml     = new XML(cfgContent);
		var zoneList   = cfgXml.Zones.Zone;
		var cocoZone   = null;

		for (var z = 0; z < zoneList.length(); z++)
		{
			if (zoneList[z].@name == "cocolani")
			{
				cocoZone = zoneList[z];
				break;
			}
		}

		if (cocoZone != null)
		{
			var roomsCfg = cocoZone.Rooms.Room;
			for (var k = 0; k < roomsCfg.length(); k++)
			{
				var rCfg   = roomsCfg[k];
				var rTribe = String(rCfg.Tribe.toString());
				if (rTribe != "")
					tribeMap[String(rCfg.@name)] = rTribe;
			}
		}
	}
	catch (e)
	{
		trace("Error loading config.xml for tribes: " + e);
	}

	for (var i = 0; i < rooms.length; i++)
	{
		var room  = rooms[i];
		var rid   = room.getId();
		var rName = room.getName();
		var tId   = tribeMap[rName];

		if (tId == undefined) tId = "1"; // default to Hula tribe

		var rVars = [];
		rVars.push({ name: "tb",   val: tId  });
		rVars.push({ name: "type", val: "0"  });

		if (rid == 3)
		{
			rVars.push({ name: "stat1", val: 3 });
			rVars.push({ name: "stat2", val: 8 });
			rVars.push({ name: "stat3", val: 2 });
			rVars.push({ name: "stat4", val: 5 });
			rVars.push({ name: "door",  val: 0 });
		}
		if (rid == 5)
		{
			rVars.push({ name: "door", val: 0 });
		}

		if (rid == 36) // Tutorial Island
		{
			rVars.push({ name: "pvt", val: true });
		}

		_server.setRoomVariables(room, null, rVars);
		trace("Set Room " + rid + " (" + rName + ") Variables: tb=" + tId);
	}

	// Apply offline bans 
	var dbase   = _server.getDatabaseManager();
	var banRows = dbase.executeQuery("SELECT `username` FROM `cc_bans` WHERE `username` != ''");
	if (banRows != null)
	{
		for (var i = 0; i < banRows.size(); i++)
			_server.banOfflineUser(banRows.get(i).getItem("username"));
	}
}

function destroy() {}

function handleRequest(cmd, params, user, fromRoom)
{
	trace("cocolani cmd: " + cmd);

	if (cmd == "tutorialDone")
	{
		dbSaveUserField(user.getName(), "dotutorial", "0");
		trace("Tutorial completed for: " + user.getName() + " - dotutorial set to 0");
	}
}


function handleInternalEvent(evt)
{
	trace("Event received: " + evt.name);

	// ---------------------------------------------------------
	// loginRequest
	// ---------------------------------------------------------
	if (evt.name == "loginRequest")
	{
		var nick = evt["nick"];
		var pass = evt["pass"];
		var chan = evt["chan"];
		var zone = _server.getCurrentZone();

		var resp     = {};
		resp._cmd    = "logKO";

		// Basic nick validation - reject empty or suspiciously long values
		if (nick == null || nick == "" || String(nick).length > 64)
		{
			resp.err = "Invalid username or password";
			_server.sendResponse(resp, -1, null, chan);
			return;
		}

		var userRows = dbSelect("cc_user",
			["ID", "username", "password", "status_ID", "email", "homeAddr", "home_ID",
			 "lastRoom", "previousTribe", "invars", "inventory", "pzl", "lvl", "lang_id",
			 "dotutorial", "happyness", "money", "skill", "mask_colors", "btl", "mask",
			 "sex", "prefs", "register_date", "mgam", "gam", "about", "medals",
			 "tribe_id", "clothing"],
			{ username: nick });

		if (userRows == null || userRows.size() == 0)
		{
			trace("Login failed - account not found: " + nick);
			resp.err = "Invalid username or password";
			_server.sendResponse(resp, -1, null, chan);
			return;
		}

		var row      = userRows.get(0);
		var username = row.getItem("username");
		var pass2    = _server.md5(_server.getSecretKey(chan) + salt + row.getItem("password"));

		if (nick != username || pass != pass2)
		{
			trace("Login failed - wrong password for: " + nick);
			resp._cmd = "logKO";
			resp.err  = "#ERR1";
			_server.sendResponse(resp, -1, null, chan);
			return;
		}

		var obj = _server.loginUser(nick, pass, chan);
		if (!obj.success)
		{
			resp.err = obj.error;
			_server.sendResponse(resp, -1, null, chan);
			return;
		}

		// Login succeeded
		var user     = _server.getUserByChannel(chan);
		var u        = _server.instance.getUserByChannel(chan);
		var statusID = Number(row.getItem("status_ID"));

		if (statusID == 7 || statusID == 8)
			user.setAsModerator(true);

		var isMod = user.isModerator();
		var id    = user.getUserId();

		var sysMsg  = "<msg t='sys'><body action='logOK' r='0'>";
		sysMsg     += "<login n='" + u.getName() + "' id='" + u.getUserId() + "' mod='" + isMod + "' />";
		sysMsg     += "</body></msg>";
		_server.sendGenericMessage(sysMsg, null, [u]);

		var now = (new Date()).getTime() / 1000;
		dbSaveUserField(nick, "IP",            user.getIpAddress());
		dbSaveUserField(nick, "lastZone",      zone.getName());
		dbSaveUserField(nick, "seisson_start", String(now));

		// Build init response
		var lastRoom = row.getItem("lastRoom");

		var lvlThresholds = String(row.getItem("lvl"));
		if (lvlThresholds == null || lvlThresholds == "")
			lvlThresholds = "20,50,100,300,800,1800,3000,4400,6000,7800,9800,12000,14400,17000";

		var skillParts = String(row.getItem("skill")).split(",");
		var skill      = {};
		skill[0]       = skillParts[0];
		skill[1]       = skillParts[1];

		resp           = {};
		resp._cmd      = "init";
		resp.custID    = 0;
		resp.name      = nick;
		resp.id        = id;
		resp.mail      = row.getItem("email");
		resp.had       = row.getItem("homeAddr");
		resp.hid       = row.getItem("home_ID");
		resp.st        = statusID;
		resp.prtb      = row.getItem("previousTribe");
		resp.invars    = row.getItem("invars");
		resp.inv       = row.getItem("inventory");
		resp.pvars     = row.getItem("pzl");
		resp.lvl       = lvlThresholds;
		resp.lang      = row.getItem("lang_id");

		var dotutorialVal = row.getItem("dotutorial");
		if (dotutorialVal == null || String(dotutorialVal) == "" || String(dotutorialVal) == "null")
		{
			dotutorialVal = "1";
			dbSaveUserField(nick, "dotutorial", "1");
			trace("First login for " + nick + " - dotutorial set to 1");
		}
		resp.dotutorial = dotutorialVal;

		resp.hp        = row.getItem("happyness");
		resp.cr        = row.getItem("money");
		resp.skill     = skill;
		resp.maskc     = row.getItem("mask_colors");
		resp.btl       = row.getItem("btl");
		resp.motd      = getDefSetting("MOTD");
		resp.mbr       = getDefSetting("usertypes");
		resp.mask      = row.getItem("mask");
		resp.sex       = row.getItem("sex");
		resp.prefs     = row.getItem("prefs");
		resp.jd        = row.getItem("register_date");
		resp.mgam      = row.getItem("mgam");
		resp.gam       = row.getItem("gam");
		resp.abt       = row.getItem("about");
		resp.medals    = row.getItem("medals");
		resp.tb        = row.getItem("tribe_id");

		// Chief check
		var chiefRows = dbSelect("cc_tribes", ["chief_id"], { ID: resp.tb });
		resp.chief    = false;
		if (chiefRows != null && chiefRows.size() > 0)
		{
			if (Number(chiefRows.get(0).getItem("chief_id")) == Number(row.getItem("ID")))
				resp.chief = true;
		}

		// Default spawn room 4 jungle birdge, 14 volcano bridge, or last room if valid
		if (Number(lastRoom) <= 1)
			resp.prm = (Number(resp.tb) == 1) ? "4" : "14"; 
		else
			resp.prm = String(lastRoom);

		var tribes    = [];
		var tribeRows = dbSelect("cc_tribes", ["ID", "name", "chief_id"], null);
		if (tribeRows != null)
		{
			for (var i = 0; i < tribeRows.size(); i++)
			{
				var tr    = tribeRows.get(i);
				var info  = {};
				info.id   = String(tr.getItem("ID"));
				info.name = String(tr.getItem("name"));
				info.chief = String(tr.getItem("chief_id"));
				tribes.push(info);
			}
		}
		resp.tribeData = tribes;

		// Buddy variables (visible on friends list)
		var buddyVars  = {};
		buddyVars.$trb = String(row.getItem("tribe_id"));
		buddyVars.$chr = String(row.getItem("sex") + "!" + row.getItem("mask") + "!" + row.getItem("mask_colors"));
		if (Number(row.getItem("homeAddr")) != -1)
			buddyVars.$had = String(row.getItem("homeAddr"));
		_server.setBuddyVariables(u, buddyVars);

		_server.sendResponse(resp, -1, null, [u]);
	}

	// ---------------------------------------------------------
	// userJoin - set user variables visible to other players
	// ---------------------------------------------------------
	else if (evt.name == "userJoin")
	{
		var r = evt["room"];
		var u = evt["user"];
		trace("User: " + u.getName() + " joined room: " + r.getName());

		var userRows = dbSelect("cc_user",
			["ID", "status_ID", "sex", "mask", "mask_colors", "clothing",
			 "happyness", "tribe_id", "lvl", "skill"],
			{ username: u.getName() });

		if (userRows == null || userRows.size() == 0) return;

		var row3  = userRows.get(0);
		var uVars = {};

		uVars.chr  = row3.getItem("sex") + "!" + row3.getItem("mask") + "!" + row3.getItem("mask_colors");
		uVars.usr  = Number(row3.getItem("status_ID"));
		uVars.clth = String(row3.getItem("clothing"));
		uVars.hpy  = String(row3.getItem("happyness"));
		uVars.trb  = String(row3.getItem("tribe_id"));
		uVars.cr   = r.getId();
		uVars.lvl  = String(row3.getItem("lvl"));
		uVars.skill = String(row3.getItem("skill"));
		uVars.pth  = 1;
		var chiefRows = dbSelect("cc_tribes", ["chief_id"], { ID: row3.getItem("tribe_id") });
		uVars.chief   = false;
		if (chiefRows != null && chiefRows.size() > 0)
		{
			if (Number(chiefRows.get(0).getItem("chief_id")) == Number(row3.getItem("ID")))
				uVars.chief = true;
		}

		_server.setUserVariables(u, uVars, true);

		// Update battle win counters when entering the battle zone
		if (r.getName() == "Battle Zone1")
		{
			var t1Wins  = 0;
			var t2Wins  = 0;
			var winRows = dbSelect("cc_tribes", ["ID", "battles_won"], null);
			if (winRows != null)
			{
				for (var i = 0; i < winRows.size(); i++)
				{
					var rowW = winRows.get(i);
					var tid  = Number(rowW.getItem("ID"));
					var bwon = Number(rowW.getItem("battles_won"));
					if      (tid == 1) t1Wins = bwon;
					else if (tid == 2) t2Wins = bwon;
				}
			}
			_server.setRoomVariables(r, null, [
				{ name: "tribe1WinsTdy", val: t1Wins },
				{ name: "tribe2WinsTdy", val: t2Wins }
			]);
		}
	}

	// ---------------------------------------------------------
	// userExit - update current room variable
	// ---------------------------------------------------------
	else if (evt.name == "userExit")
	{
		var user = evt.user;
		var room = evt.room;
		_server.setUserVariables(user, { cr: room.getId() }, true);
		trace("User: " + user.getName() + " left room: " + room.getName());
	}

	// ---------------------------------------------------------
	// logOut / userLost - persist last room and session end time
	// ---------------------------------------------------------
	else if (evt.name == "logOut" || evt.name == "userLost")
	{
		var u      = evt.user;
		var r      = evt.roomIds;
		var myRoom = r[0];
		var now    = String((new Date()).getTime() / 1000);

		dbSaveUserField(u.getName(), "lastRoom",    String(myRoom));
		dbSaveUserField(u.getName(), "seisson_end", now);

		trace("Player: " + u.getName() + (evt.name == "logOut" ? " logged out." : " timed out."));
	}

	// ---------------------------------------------------------
	// pubMsg - check for swear words before dispatching
	// ---------------------------------------------------------
	else if (evt.name == "pubMsg")
	{
		var sourceRoom  = evt.room;
		var senderUser  = evt.user;
		var message     = evt.msg;
		var swear       = checkSwears(message);

		if (swear)
		{
			var lang    = dbGetUserField(senderUser.getName(), "lang_id");
			if (lang == null) lang = "0";
			_server.kickUser(senderUser, 3, getMsg(lang,
				"Profanity is not allowed. You have been kicked. Repeat and you will be banned.",
				"ممنوع السب والشتم ، لقد تم طردك ، إذا حاولت السب مرة أخرى سيتم حظرك."
			));
			dbSaveUserField(senderUser.getName(), "swear",     "true");
			dbSaveUserField(senderUser.getName(), "lastSwear", String(swear));
		}
		else
		{
			_server.dispatchPublicMessage(message, sourceRoom, senderUser);
		}
	}

	// ---------------------------------------------------------
	// privMsg - check for swear words before dispatching
	// ---------------------------------------------------------
	else if (evt.name == "privMsg")
	{
		var sourceRoom = evt.room;
		var sender     = evt.sender;
		var recipient  = evt.recipient;
		var message    = evt.msg;
		var swear      = checkSwears(message);

		if (swear)
		{
			var lang = dbGetUserField(sender.getName(), "lang_id");
			if (lang == null) lang = "0";
			_server.kickUser(sender, 3, getMsg(lang,
				"Profanity is not allowed. You have been kicked. Repeat and you will be banned.",
				"ممنوع السب والشتم ، لقد تم طردك ، إذا حاولت السب مرة أخرى سيتم حظرك."
			));
			dbSaveUserField(sender.getName(), "swear",     "true");
			dbSaveUserField(sender.getName(), "lastSwear", String(swear));
		}
		else
		{
			_server.dispatchPrivateMessage(message, sourceRoom, sender, recipient);
		}
	}

	else if (evt.name == "newRoom") {}
}

// =============================================================
// DB UTILITY FUNCTIONS  
// =============================================================

function dbEscape(val)
{
	if (val == null || val == undefined) return "";
	return _server.escapeQuotes(String(val));
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

function dbSelect(table, columns, where)
{
	if (!isValidIdentifier(table)) { trace("[db] BLOCKED invalid table: " + table); return null; }
	var colStr = "*";
	if (columns != "*" && columns != null && columns instanceof Array)
	{
		var safe = [];
		for (var i = 0; i < columns.length; i++)
		{
			if (!isValidIdentifier(columns[i])) { trace("[db] BLOCKED invalid column: " + columns[i]); return null; }
			safe.push("`" + columns[i] + "`");
		}
		colStr = safe.join(", ");
	}
	var sql = "SELECT " + colStr + " FROM `" + table + "`";
	if (where != null)
	{
		var conds = [];
		for (var col in where)
		{
			if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid where col: " + col); return null; }
			conds.push("`" + col + "` = '" + dbEscape(where[col]) + "'");
		}
		if (conds.length > 0) sql += " WHERE " + conds.join(" AND ");
	}
	var dbase = _server.getDatabaseManager();
	return dbase.executeQuery(sql);
}

function dbGetUserData(username, fields)
{
	var result = dbSelect("cc_user", fields, { username: username });
	if (result != null && result.size() > 0)
	{
		var row  = result.get(0);
		var data = {};
		for (var i = 0; i < fields.length; i++)
		{
			var v           = row.getItem(fields[i]);
			data[fields[i]] = (v != null) ? String(v) : "";
		}
		return data;
	}
	return null;
}

function dbGetUserField(username, field)
{
	var data = dbGetUserData(username, [field]);
	if (data != null) return data[field];
	return null;
}

function dbSaveUserField(username, field, value)
{
	if (!isValidIdentifier(field)) { trace("[db] BLOCKED invalid field: " + field); return false; }
	var sql   = "UPDATE `cc_user` SET `" + field + "` = '" + dbEscape(value) + "' WHERE `username` = '" + dbEscape(username) + "'";
	var dbase = _server.getDatabaseManager();
	return dbase.executeCommand(sql);
}

// =============================================================
// GENERAL HELPERS
// =============================================================

// lang_id "0" = English, "1" = Arabic
function getMsg(lang, en, ar)
{
	return (String(lang) == "1") ? ar : en;
}

function getDefSetting(settingName)
{
	if (!isValidIdentifier(settingName)) return "";
	var dbase = _server.getDatabaseManager();
	var res   = dbase.executeQuery("SELECT `" + settingName + "` FROM `cc_def_settings` WHERE `id` = 1 LIMIT 1");
	if (res == null || res.size() == 0) return "";
	var val = res.get(0).getItem(settingName);
	return (val != null) ? String(val) : "";
}

function checkSwears(txt)
{
	var dbase   = _server.getDatabaseManager();
	var swrRows = dbase.executeQuery("SELECT `name` FROM `cc_swear_words`");
	if (swrRows == null) return false;
	for (var i = 0; i < swrRows.size(); i++)
	{
		var word = String(swrRows.get(i).getItem("name"));
		if (txt.indexOf(word) >= 0)
			return word;
	}
	return false;
}
