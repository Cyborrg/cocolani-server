// =====================================================
// gameManager.as
// Handles mini-games logic, rewards and high scores.
// Also has shared logic for granting specific puzzle pieces
// based on medals earned across multiple games.
//
// Current anticheat measures:
//  - Server-side MD5 verification
//    	Hash: MD5(score + "IPledgePeaceAndLoveOnEarth" + timestamp + userId)
// 		
//  - Timestamp freshness check (-+5 minutes)
//  - Score ceiling enforcement via cc_game_config.max_score default at 60k, you might want to change it.
//  - params.win range enforcement (must be 0 or 1)
//  - SENDHACK/hack command will immediate ban, those are sent by client if client found an cheated score
//  - banUser() sets cc_user.hacks="True", inserts into cc_bans,
//    notifies client, then calls _server.banUser() (BAN_BY_NAME)
//  - logSecurityEvent() writes to cc_security_log
//
//  *** IMPORTANT NOTE ***
//	Those are really basic measures and can be easily bypassed
//  but since we can't update the swf and share them we will keep the original behaviour.
//  I totally recommend updating the client and the emulator code to add better security measures if you plan to go live with this.
//  See cocolani.swf.com.sceneloader in gamesConnector, around line ~420 for more info.
// =====================================================



// Secret key used by client
// It is recommended that you change the SECRET value here and in the swf you plan to use!
// See cocolani.swf.com.sceneloader in gamesConnector, around line ~420 for more info.
var SECRET = "IPledgePeaceAndLoveOnEarth";



function init()
{
}

function destroy()
{
}




function md5Server(str)
{
	try
	{
		var md  = java.security.MessageDigest.getInstance("MD5");
		var buf = java.lang.String(str).getBytes("UTF-8");
		md.update(buf, 0, buf.length); 
		var digest = md.digest();
		var hex = "";
		for (var i = 0; i < digest.length; i++)
		{
			var b = digest[i] & 0xFF;
			if (b < 16) hex += "0";
			hex += java.lang.Integer.toHexString(b);
		}
		return hex;
	}
	catch (e)
	{
		trace("[security] md5Server error: " + e);
		return "";
	}
}


function logSecurityEvent(username, reason, detail)
{
	trace("[SECURITY] user=" + username + " reason=" + reason + " detail=" + detail);
	try
	{
		dbInsert("cc_security_log", {
			username: username,
			reason:   reason,
			detail:   String(detail).substring(0, 255),
			ts:       String(new Date().getTime())
		});
	}
	catch (e) { trace("[security] logSecurityEvent DB error: " + e); }
}


function banUser(user, reason)
{
	var uname = user.getName();
	var uip   = user.getIpAddress();
	trace("[SECURITY] BANNING " + uname + " ip=" + uip + " reason=" + reason);

	dbSaveUserField(uname, "hacks", "True");


	var dbase = _server.getDatabaseManager();

	var banSqlName = "INSERT INTO `cc_bans` (`username`, `ip`, `reason`, `until`, `banned_by`, `ban_type`) VALUES ('"
	               + dbEscape(uname) + "', '"
	               + dbEscape(uip)   + "', '"
	               + dbEscape(reason) + "', '', 'gameManager', 'name')";
	try { dbase.executeCommand(banSqlName); }
	catch (e) { trace("[security] cc_bans name-insert error: " + e); }

	var banSqlIP = "INSERT INTO `cc_bans` (`ip`, `username`, `reason`, `until`, `banned_by`, `ban_type`) VALUES ('"
	             + dbEscape(uip)   + "', '', '"
	             + dbEscape(reason) + "', '', 'gameManager', 'ip')";
	try { dbase.executeCommand(banSqlIP); }
	catch (e) { trace("[security] cc_bans ip-insert error: " + e); }

	logSecurityEvent(uname, reason, "auto-ban ip=" + uip);

	var resp    = {};
	resp._cmd   = "interface";
	resp.sub    = "banned";
	resp.reason = reason;
	try { _server.sendResponse(resp, -1, null, [user]); }
	catch (e) { trace("[security] sendResponse error: " + e); }

	try { _server.banUser(user, 3, reason, _server.BAN_BY_NAME); }
	catch (e) { trace("[security] banUser(name) error: " + e); }
	try { _server.banUser(user, 3, reason, _server.BAN_BY_IP); }
	catch (e) { trace("[security] banUser(ip) error: " + e); }
}

// =========================================================
// MAIN REQUEST HANDLER
// =========================================================
function handleRequest(cmd, params, user, fromRoom)
{
	trace("cmd received: " + cmd);

	var username = user.getName();

	// ---------------------------------------------------------
	// list - Show available games
	// ---------------------------------------------------------
	if (cmd == "list")
	{
		var res = dbSelect("cc_games", "*", null);
		var listnow = "";

		if (res != null)
		{
			for (var i = 0; i < res.size(); i++)
			{
				var row = res.get(i);
				if (i > 0) listnow += "#";
				listnow += row.getItem("id") + "%" + row.getItem("name");
			}
		}

		var resp = {};
		resp._cmd = "interface";
		resp.sub  = "med";
		resp.list = listnow;
		resp.act  = params.act;
		resp.usr  = Number(user.getUserId());
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// plygame - Record that the user has played a game
	// ---------------------------------------------------------
	else if (cmd == "plygame")
	{
		if (!isValidInt(params.id)) { trace("BLOCKED: invalid game id"); return; }

		var gid     = params.id;
		var prevGam = dbGetUserField(username, "gam");
		if (prevGam == null) prevGam = "";

		if (hasInList(prevGam, gid)) return; // already recorded

		var newGam = appendToList(prevGam, gid);
		dbSaveUserField(username, "gam", newGam);

		var resp = {};
		resp._cmd   = "gameRep";
		resp.newput = newGam;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// pracBattle - challenge another player to a practice battle
	// ---------------------------------------------------------
	else if (cmd == "pracBattle")
	{
		if (!isValidInt(params.uid)) { trace("BLOCKED: invalid uid"); return; }

		var targetUser = _server.getUserById(Number(params.uid));
		if (targetUser == null) return;

		var targetName = dbGetUserField(username, "username");

		var resp = {};
		resp._cmd = "sceneRepAuto";
		resp.sub  = "btlChallenge";
		resp.nm   = targetName;
		resp.uid  = params.uid;
		_server.sendResponse(resp, -1, null, [targetUser]);
	}

	// ---------------------------------------------------------
	// hack - Client detected a cheat attempt and reported it.
	// ---------------------------------------------------------
	else if (cmd == "hack")
	{
		var hackGid = isValidInt(params.gid) ? String(params.gid) : "?";
		var hackHs  = isValidUInt(params.hs)  ? String(params.hs)  : "?";
		logSecurityEvent(username, "hack_reported_by_client", "gid=" + hackGid + " hs=" + hackHs);
		banUser(user, "You've been Banned.");
	}

	// ---------------------------------------------------------
	// getHS - Fetch top 20 high scores for a game
	// ---------------------------------------------------------
	else if (cmd == "getHS")
	{
		if (!isValidInt(params.gid)) { trace("BLOCKED: invalid gid"); return; }

		var rHS = dbSelectOrdered(
			"cc_highscores",
			["username", "score"],
			{game_id: params.gid},
			"score", "DESC", 20
		);

		var hsStr = "";
		if (rHS != null)
		{
			for (var i = 0; i < rHS.size(); i++)
			{
				var rowHS = rHS.get(i);
				if (i > 0) hsStr += "\x02";
				hsStr += rowHS.getItem("username") + "\x01" + rowHS.getItem("score");
			}
		}
		if (hsStr == "") hsStr = "";

		var resp = {};
		resp._cmd = "gameRep";
		resp.hs   = hsStr;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// submitHS - Game over: save score, award medals and money
	// ---------------------------------------------------------
	else if (cmd == "submitHS")
	{
		if (!isValidInt(params.gid) || !isValidUInt(params.hs))
		{
			trace("BLOCKED: invalid gid or score");
			return;
		}

		var gid   = params.gid;
		var score = Number(params.hs);

		// security: validate win flag (must be 0 or 1)
		if (params.win != null && params.win !== 0 && params.win !== 1 &&
		    params.win != "0" && params.win != "1")
		{
			logSecurityEvent(username, "invalid_win_param", "win=" + params.win + " gid=" + gid);
			banUser(user, "You've been Banned.");
			return;
		}

		// security: timestamp freshness (client must be within +-5 min)
		// params.prm = new Date().getTime() sent by the client
		var serverNow  = new Date().getTime();
		var clientTime = Number(params.prm);
		if (isNaN(clientTime) || Math.abs(serverNow - clientTime) > 300000)
		{
			logSecurityEvent(username, "stale_timestamp", "prm=" + params.prm + " serverNow=" + serverNow + " gid=" + gid);
			banUser(user, "You've been Banned.");
			return;
		}

		
		var expectedHash = md5Server(String(score) + SECRET + String(params.prm) + String(user.getUserId()));
		if (params.prm2 == null || String(params.prm2).toLowerCase() != expectedHash)
		{
			logSecurityEvent(username, "hash_mismatch", "expected=" + expectedHash + " got=" + params.prm2 + " gid=" + gid + " score=" + score);
			banUser(user, "You've been Banned.");
			return;
		}

		trace("submitHS: " + username + " scored " + score + " in game " + gid);

		var userData = dbGetUserData(username, ["inventory", "invars", "medals", "pzl", "tribe_ID"]);
		if (userData == null) return;

		var prevInv     = userData.inventory;
		var prevInvars  = userData.invars;
		var prevMeds    = userData.medals;
		var userPzl     = userData.pzl;
		var playerTribe = userData.tribe_ID;

		var rConfig = dbSelect("cc_game_config", "*", {game_id: gid});
		if (rConfig == null || rConfig.size() == 0)
		{
			trace("Game ID " + gid + " not found in cc_game_config");
			return;
		}

		var rowConfig = rConfig.get(0);
		var S1       = Number(rowConfig.getItem("bronze_min"));
		var S2       = Number(rowConfig.getItem("silver_min"));
		var S3       = Number(rowConfig.getItem("gold_min"));
		var M1       = Number(rowConfig.getItem("money_min_score"));
		var M2       = Number(rowConfig.getItem("money_max_score"));
		var average  = Number(rowConfig.getItem("money_divisor"));
		var limit    = Number(rowConfig.getItem("money_limit"));
		var tribeN   = Number(rowConfig.getItem("tribe_id"));
		var maxScore = Number(rowConfig.getItem("max_score")); // 0 = not enforced

		// score ceiling check.
		if (maxScore > 0 && score > maxScore)
		{
			logSecurityEvent(username, "score_overflow", "score=" + score + " max=" + maxScore + " gid=" + gid);
			banUser(user, "You've been Banned.");
			return;
		}

		// security checks passed
		dbInsert("cc_highscores", {game_id: gid, username: username, score: score});

		// Game 21 (Crazy Balls): tribe-based reward column
		if (gid == 21)
		{
			tribeN = (playerTribe == 1) ? 0 : 1;
		}

		// -----------------------------------------------------------------------
		// Per-game item/puzzle rewards
		// -----------------------------------------------------------------------
		var tier        = determineMedalTier(score, S1, S2, S3);
		trace("submitHS: " + username + " scored " + score + " in game " + gid + " | thresholds bronze=" + S1 + " silver=" + S2 + " gold=" + S3 + " | tier=" + tier);
		var gameRewards = loadGameRewards(gid);
		for (var ri = 0; ri < gameRewards.length; ri++)
		{
			var rw = gameRewards[ri];

			if (tier < rw.min_tier) continue;

			if (rw.once_check_field != null && rw.once_check_value != null)
			{
				var guardVal = userData[rw.once_check_field];
				if (guardVal == null) guardVal = "";
				if (hasInList(guardVal, rw.once_check_value)) continue;
			}

			if (rw.reward_type == "invars" || rw.reward_type == "item_and_invars")
			{
				if (rw.invars_id != null)
				{
					prevInvars = appendToList(prevInvars, rw.invars_id);
					dbSaveUserField(username, "invars", prevInvars);
					userData.invars = prevInvars; // keep userData in sync for next iteration

					var resp = {};
					resp._cmd   = "sceneRep";
					resp.sub    = "itemReward";
					resp.invvar = prevInvars;
					_server.sendResponse(resp, -1, null, [user]);
				}
			}

			// item reward
			if (rw.reward_type == "item" || rw.reward_type == "item_and_invars")
			{
				if (rw.item_obj_id != null)
				{
					var rwItem = buildInvStringFromObjId(rw.item_obj_id);
					if (rwItem != null)
					{
						prevInv = appendToInventory(prevInv, rwItem);
						dbSaveUserField(username, "inventory", prevInv);
						userData.inventory = prevInv;

						var resp = {};
						resp._cmd    = "buy";
						resp.adinv   = rwItem;
						resp.totalInv = prevInv;
						_server.sendResponse(resp, -1, null, [user]);
					}
				}
			}

			// pzl reward
			if (rw.reward_type == "pzl")
			{
				if (rw.pzl_id != null)
				{
					userPzl = appendToList(userPzl, rw.pzl_id);
					dbSaveUserField(username, "pzl", userPzl);

					var resp = {};
					resp._cmd   = "sceneRep";
					resp.sub    = "puz";
					resp.pzlupd = userPzl;
					_server.sendResponse(resp, -1, null, [user]);
				}
			}
		}

		// -----------------------------------------------------------------------
		// Cross-game pzl awards
		// Awarded when current game achieves gold AND all other
		// required games already have gold medals.
		// -----------------------------------------------------------------------
		if (tier == 3)
		{
			var pzlAwards = loadGamePzlAwards();
			for (var pi = 0; pi < pzlAwards.length; pi++)
			{
				var pa = pzlAwards[pi];

				if (hasInList(userPzl, pa.pzl_id)) continue;

				var currentInSet = false;
				for (var qi = 0; qi < pa.required.length; qi++)
				{
					if (pa.required[qi] == "" + gid) { currentInSet = true; break; }
				}
				if (!currentInSet) continue;

				var allGold = true;
				for (var qi = 0; qi < pa.required.length; qi++)
				{
					var reqGid = pa.required[qi];
					if (reqGid == "" + gid) continue; // current game just earned gold
					if (!hasMedal(prevMeds, reqGid, 3))
					{
						allGold = false;
						break;
					}
				}

				if (allGold)
				{
					userPzl = appendToList(userPzl, pa.pzl_id);
					dbSaveUserField(username, "pzl", userPzl);

					var resp = {};
					resp._cmd   = "sceneRep";
					resp.sub    = "puz";
					resp.id     = "" + pa.pzl_id;
					resp.pzlupd = userPzl;
					_server.sendResponse(resp, -1, null, [user]);
				}
			}
		}

		// -----------------------------------------------------------------------
		// Medal awards
		// -----------------------------------------------------------------------
		var hasBronze = hasMedal(prevMeds, gid, 1);
		var hasSilver = hasMedal(prevMeds, gid, 2);
		var hasGold   = hasMedal(prevMeds, gid, 3);

		if (tier == 1 && !hasBronze && !hasSilver && !hasGold)
		{
			grantMedal(user, prevMeds, gid, 1);
		}
		else if (tier == 2 && !hasSilver && !hasGold)
		{
			grantMedal(user, prevMeds, gid, 2);
		}
		else if (tier == 3 && !hasGold)
		{
			grantMedal(user, prevMeds, gid, 3);
		}

		// -----------------------------------------------------------------------
		// Money reward
		// -----------------------------------------------------------------------
		if (score >= M1)
		{
			var mfg = (score >= M2) ? limit : Math.ceil(score / average);

			var playerMoney = dbGetUserField(username, "money");
			if (playerMoney == null) playerMoney = "0,0";
			var moneyArray = playerMoney.split(",");
			moneyArray[tribeN] = String(Number(moneyArray[tribeN]) + mfg);
			var newMoney = moneyArray[0] + "," + moneyArray[1];

			dbSaveUserField(username, "money", newMoney);

			var resp = {};
			resp._cmd = "purse";
			resp.cr   = newMoney;
			_server.sendResponse(resp, -1, null, [user]);
		}
	}
}

function handleInternalEvent(evt)
{
}

// =========================================================
// DB UTILITY FUNCTIONS
// =========================================================

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
		if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
		      (c >= '0' && c <= '9') || c == '_'))
		{
			return false;
		}
	}
	return true;
}

function dbSelect(table, columns, where)
{
	if (!isValidIdentifier(table)) { trace("[db] BLOCKED invalid table: " + table); return null; }
	var colStr = "*";
	if (columns != "*" && columns != null && columns != undefined && columns instanceof Array)
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
	if (where != null && where != undefined)
	{
		var conds = [];
		for (var col in where)
		{
			if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid where-col: " + col); return null; }
			conds.push("`" + col + "` = '" + dbEscape(where[col]) + "'");
		}
		if (conds.length > 0) sql += " WHERE " + conds.join(" AND ");
	}
	var dbase = _server.getDatabaseManager();
	return dbase.executeQuery(sql);
}

function dbGetUserData(username, fields)
{
	var result = dbSelect("cc_user", fields, {username: username});
	if (result != null && result.size() > 0)
	{
		var row = result.get(0);
		var data = {};
		for (var i = 0; i < fields.length; i++)
		{
			var v = row.getItem(fields[i]);
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
	var sql = "UPDATE `cc_user` SET `" + field + "` = '" + dbEscape(value) + "' WHERE `username` = '" + dbEscape(username) + "'";
	var dbase = _server.getDatabaseManager();
	var success = dbase.executeCommand(sql);
	if (success) trace("[db] saved field=" + field + " for user=" + username);
	return success;
}

function isValidInt(val)
{
	if (val == null || val == undefined || val == "") return false;
	var n = Number(val);
	return !isNaN(n) && n == Math.floor(n);
}

function isValidUInt(val)
{
	if (val == null || val == undefined || val == "") return false;
	var n = Number(val);
	return !isNaN(n) && n >= 0 && n == Math.floor(n);
}

// ---------------------------------------------------------
// Helper: append a value to a comma-separated string
// ---------------------------------------------------------
function appendToList(existing, value)
{
	if (existing != null && existing.length != 0) return existing + "," + value;
	return "" + value;
}

// ---------------------------------------------------------
// Helper: append an item string to pipe-separated inventory
// ---------------------------------------------------------
function appendToInventory(store, item)
{
	if (store != null && store.length != 0) return store + "|" + item;
	return item;
}

// ---------------------------------------------------------
// Helper: build inventory string from cc_invlist by objID
// Returns: "objID~objID~swfID~desc~name~type~exchange~kind~lvl"
// ---------------------------------------------------------
function buildInvStringFromObjId(objId)
{
	if (objId == null || objId == "") return null;
	var res = dbSelect("cc_invlist", ["objID","swfID","name","description","type","exchange","kind","lvl"], {objID: objId});
	if (res == null || res.size() == 0) return null;
	var row = res.get(0);
	var oid  = row.getItem("objID");
	var swf  = row.getItem("swfID");
	var name = row.getItem("name");
	var desc = row.getItem("description");
	var type = row.getItem("type");
	var exch = row.getItem("exchange");
	var kind = row.getItem("kind");
	var lvl  = row.getItem("lvl");
	return oid + "~" + oid + "~" + swf + "~" + desc + "~" + name + "~" + type + "~" + exch + "~" + kind + "~" + lvl;
}

// ---------------------------------------------------------
// Helper: insert a row into a table
// ---------------------------------------------------------
function dbInsert(table, values)
{
	if (!isValidIdentifier(table)) { trace("[db] BLOCKED invalid table: " + table); return false; }
	var cols = [];
	var vals = [];
	for (var col in values)
	{
		if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid col: " + col); return false; }
		cols.push("`" + col + "`");
		vals.push("'" + dbEscape(values[col]) + "'");
	}
	if (cols.length == 0) return false;
	var sql = "INSERT INTO `" + table + "` (" + cols.join(", ") + ") VALUES (" + vals.join(", ") + ")";
	var dbase = _server.getDatabaseManager();
	return dbase.executeCommand(sql);
}

// ---------------------------------------------------------
// Helper: SELECT with ORDER BY and LIMIT support
// ---------------------------------------------------------
function dbSelectOrdered(table, columns, where, orderCol, orderDir, limitN)
{
	if (!isValidIdentifier(table)) { trace("[db] BLOCKED invalid table: " + table); return null; }
	var colStr = "*";
	if (columns != "*" && columns != null && columns != undefined && columns instanceof Array)
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
	if (where != null && where != undefined)
	{
		var conds = [];
		for (var col in where)
		{
			if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid where-col: " + col); return null; }
			conds.push("`" + col + "` = '" + dbEscape(where[col]) + "'");
		}
		if (conds.length > 0) sql += " WHERE " + conds.join(" AND ");
	}
	if (orderCol != null && isValidIdentifier(orderCol))
	{
		var dir = (orderDir == "DESC") ? "DESC" : "ASC";
		sql += " ORDER BY `" + orderCol + "` " + dir;
	}
	if (limitN != null && isValidUInt(limitN))
	{
		sql += " LIMIT " + Number(limitN);
	}
	var dbase = _server.getDatabaseManager();
	return dbase.executeQuery(sql);
}

// ---------------------------------------------------------
// Helper: load per-game rewards from cc_game_rewards
// ---------------------------------------------------------
function loadGameRewards(gameId)
{
	var res = dbSelect("cc_game_rewards", "*", {game_id: gameId});
	if (res == null) return [];
	var rewards = [];
	for (var i = 0; i < res.size(); i++)
	{
		var row = res.get(i);
		rewards.push({
			min_tier:         Number(row.getItem("min_tier")),
			reward_type:      row.getItem("reward_type"),
			pzl_id:           row.getItem("pzl_id"),
			item_obj_id:      row.getItem("item_obj_id"),
			invars_id:        row.getItem("invars_id"),
			once_check_field: row.getItem("once_check_field"),
			once_check_value: row.getItem("once_check_value")
		});
	}
	return rewards;
}

// ---------------------------------------------------------
// Helper: load cross-game pzl awards from cc_game_pzl_award
// Returns array of {pzl_id: str, required: [str, ...]}
// ---------------------------------------------------------
function loadGamePzlAwards()
{
	var res = dbSelect("cc_game_pzl_award", "*", null);
	if (res == null) return [];
	var awards = [];
	for (var i = 0; i < res.size(); i++)
	{
		var row = res.get(i);
		awards.push({
			pzl_id:   String(row.getItem("pzl_id")),
			required: String(row.getItem("required_gold_game_ids")).split(",")
		});
	}
	return awards;
}

// ---------------------------------------------------------
// Helper: exact entry check in a comma-separated list.
// ---------------------------------------------------------
function hasInList(list, value)
{
	var padded = "," + String(list) + ",";
	return padded.indexOf("," + String(value) + ",") != -1;
}

// ---------------------------------------------------------
// Helper: check if a medals string contains an exact entry
// for the given game id and tier.
// ---------------------------------------------------------
function hasMedal(meds, gid, tier)
{
	return hasInList(meds, "" + gid + ":" + tier);
}

// ---------------------------------------------------------
// Helper: determine medal tier from score thresholds
// Returns 1 (bronze), 2 (silver), 3 (gold), or 0 (none)
// ---------------------------------------------------------
function determineMedalTier(score, S1, S2, S3)
{
	if (score >= S3) return 3;
	if (score >= S2) return 2;
	if (score >= S1) return 1;
	return 0;
}

// ---------------------------------------------------------
// Helper: grant or upgrade a medal for a game.
// ---------------------------------------------------------
function grantMedal(user, prevMeds, gid, tom)
{
	var resp = {};
	resp._cmd   = "interface";
	resp.sub    = "med";
	resp.newmed = gid + ":" + tom;

	if (prevMeds == "")
	{
		resp.md = gid + ":" + tom;
	}
	else
	{
		var bronze = gid + ":1";
		var silver = gid + ":2";
		if (prevMeds.indexOf(bronze) != -1)
		{
			resp.md = prevMeds.replace(bronze, gid + ":" + tom);
		}
		else if (prevMeds.indexOf(silver) != -1)
		{
			resp.md = prevMeds.replace(silver, gid + ":" + tom);
		}
		else
		{
			resp.md = prevMeds + "," + gid + ":" + tom;
		}
	}

	dbSaveUserField(user.getName(), "medals", resp.md);
	_server.sendResponse(resp, -1, null, [user]);
}