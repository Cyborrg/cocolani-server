var antihack = new Object();
var counter = new Object();

function init(){

}

function destroy(){
		
}

function handleInternalEvent(evt){
    
    if (evt.name == "logOut" || evt.name == "userLost") 
    {
	    var user = evt.user;
        var username = user.getName();
        if (antihack.username != undefined) delete antihack.username;
    }
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

function dbUpdate(table, setValues, where)
{
	if (!isValidIdentifier(table)) { trace("[db] BLOCKED invalid table: " + table); return false; }
	var parts = [];
	for (var col in setValues)
	{
		if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid set-col: " + col); return false; }
		parts.push("`" + col + "` = '" + dbEscape(setValues[col]) + "'");
	}
	if (parts.length == 0) return false;
	var sql = "UPDATE `" + table + "` SET " + parts.join(", ");
	if (where != null && where != undefined)
	{
		var conds = [];
		for (var col in where)
		{
			if (!isValidIdentifier(col)) { trace("[db] BLOCKED invalid where-col: " + col); return false; }
			conds.push("`" + col + "` = '" + dbEscape(where[col]) + "'");
		}
		if (conds.length > 0) sql += " WHERE " + conds.join(" AND ");
	}
	var dbase = _server.getDatabaseManager();
	return dbase.executeCommand(sql);
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
			data[fields[i]] = (v != null) ? v : "";
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
	return dbase.executeCommand(sql);
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

// =========================================================
// PUZZLE-SPECIFIC HELPERS
// =========================================================

// ---------------------------------------------------------
// Helper: Remove first item matching objID from inventory string
// Returns {found: bool, newStore: string}
// ---------------------------------------------------------
function removeFromInventory(store, objID)
{
	var result = {found: false, newStore: store};
	var storeStr = "" + store + "";
	var arr = storeStr.split("|");
	
	for (var i = 0; i < arr.length; i++)
	{
		var parts = arr[i].split("~");
		if (parts.length > 0 && parts[0] == objID)
		{
			arr.splice(i, 1);
			result.newStore = arr.join("|");
			result.found = true;
			break;
		}
	}
	return result;
}

// ---------------------------------------------------------
// Helper: Append a value to a comma-separated string
// ---------------------------------------------------------
function appendToList(existing, value)
{
	if (existing.length != 0) return "" + existing + "," + value + "";
	return "" + value;
}

// ---------------------------------------------------------
// Helper: Append an item (inv string) to inventory
// ---------------------------------------------------------
function appendToInventory(store, item)
{
	if (store.length != 0) return "" + store + "|" + item + "";
	return item;
}

// ---------------------------------------------------------
// Helper: Build inventory string from cc_invlist by objID
// Returns: "objID~objID~swfID~description~name~type~exchange~kind~lvl"
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
// Helper: Load bot config from cc_puzzle_bots
// ---------------------------------------------------------
function loadBotConfig(botId)
{
	var res = dbSelect("cc_puzzle_bots", "*", {bot_id: botId});
	if (res == null || res.size() == 0) return null;
	var row = res.get(0);
	return {
		bot_id:          row.getItem("bot_id"),
		bot_type:        row.getItem("bot_type"),
		prize_obj_id: row.getItem("prize_obj_id"),
		money_reward: Number(row.getItem("money_reward"))
	};
}

// ---------------------------------------------------------
// Helper: Load required items for a bot from cc_puzzle_bot_items
// Returns array of objID integers
// ---------------------------------------------------------
function loadBotItems(botId)
{
	var res = dbSelect("cc_puzzle_bot_items", ["item_obj_id"], {bot_id: botId});
	if (res == null) return [];
	var items = [];
	for (var i = 0; i < res.size(); i++)
	{
		items.push(res.get(i).getItem("item_obj_id"));
	}
	return items;
}

// ---------------------------------------------------------
// Helper: Check if a puzzle/reward ID is already in pvars
// pvars is a comma-separated list, e.g. "3,7,12"
// ---------------------------------------------------------
function pzlAlreadyClaimed(pvars, pzlId)
{
	if (pvars == null || pvars == "" || pzlId == null || pzlId == "") return false;
	var arr = ("" + pvars).split(",");
	for (var i = 0; i < arr.length; i++)
	{
		if (arr[i] == "" + pzlId) return true;
	}
	return false;
}

// ---------------------------------------------------------
// Helper: Build a needs lookup string ",id1,id2,...,idN,"
// ---------------------------------------------------------
function buildNeedsString(items)
{
	var s = ",";
	for (var i = 0; i < items.length; i++)
	{
		s += items[i] + ",";
	}
	return s;
}



// ---------------------------------------------------------
// Helper: Load reward config for a room (+ optional choice)
// ---------------------------------------------------------
function loadRewardConfig(roomId, choiceId)
{
	var where = {room_id: roomId};
	if (choiceId != null && choiceId != undefined)
	{
		where.choice_id = choiceId;
	}
	var res = dbSelect("cc_puzzle_rewards", "*", where);
	if (res == null || res.size() == 0) return null;
	var row = res.get(0);
	return {
		reward_type:        row.getItem("reward_type"),
		money_amount:       Number(row.getItem("money_amount")),
		item_obj_id:        row.getItem("item_obj_id"),
		pzl_id:             Number(row.getItem("pzl_id")),
		remove_item_obj_id: row.getItem("remove_item_obj_id"),
		add_invars_id:      row.getItem("add_invars_id")
	};
}

// ---------------------------------------------------------
// Helper: Load all reward configs for a room
// Returns array of reward config objects
// ---------------------------------------------------------
function loadRoomRewards(roomId)
{
	var res = dbSelect("cc_puzzle_rewards", "*", {room_id: roomId});
	if (res == null) return [];
	var rewards = [];
	for (var i = 0; i < res.size(); i++)
	{
		var row = res.get(i);
		rewards.push({
			choice_id:          row.getItem("choice_id"),
			reward_type:        row.getItem("reward_type"),
			money_amount:       Number(row.getItem("money_amount")),
			item_obj_id:        row.getItem("item_obj_id"),
			pzl_id:             Number(row.getItem("pzl_id")),
			remove_item_obj_id: row.getItem("remove_item_obj_id"),
			add_invars_id:      row.getItem("add_invars_id")
		});
	}
	return rewards;
}

// ---------------------------------------------------------
// Helper: Load energy price for a tier
// ---------------------------------------------------------
function loadEnergyPrice(tierId)
{
	var res = dbSelect("cc_energy_prices", ["price"], {tier_id: tierId});
	if (res == null || res.size() == 0) return null;
	return Number(res.get(0).getItem("price"));
}

// ---------------------------------------------------------
// Helper: Load tuberide price for a tier (1=2min, 2=3min, 3=5min)
// Prices live in cc_puzzle_tuberide_prices and must match @cost in NPC XML
// ---------------------------------------------------------
function loadTuberidePrice(tierId)
{
	var res = dbSelect("cc_tuberide_prices", ["price"], {tier_id: tierId});
	if (res == null || res.size() == 0) return null;
	return Number(res.get(0).getItem("price"));
}

// ---------------------------------------------------------
// Helper: Load a puzzle config value
// ---------------------------------------------------------
function loadPuzzleConfig(key)
{
	var res = dbSelect("cc_puzzle_config", ["config_value"], {config_key: key});
	if (res == null || res.size() == 0) return null;
	return res.get(0).getItem("config_value");
}

// =========================================================
// MAIN REQUEST HANDLER
// =========================================================
function handleRequest(cmd, params, user, fromRoom, protocol) {

    trace("cmd : " + cmd);

    var username = user.getName();
	var userData = dbGetUserData(username, ["inventory", "lang_id", "happyness", "pzl", "invars"]);
	if (userData == null) return;

	var store  = userData.inventory;
	var lang   = (userData.lang_id != "") ? userData.lang_id : "0";
	var hp     = (userData.happyness != "") ? userData.happyness : "0";
	var pvars  = userData.pzl;
	var invars = userData.invars;
	var invtrick  = "," + invars;
	var invtrick1 = "," + invars + ",";

	// =============================================================
	// BOT_give - NPC item exchange (simple & complex bots)
	// =============================================================
	if (cmd == "BOT_give") {
		trace(params.id);

		trace("botid: " + params.botid);
		if (!isValidInt(params.botid)) { trace("BLOCKED: invalid botid"); return; }

		var botCfg = loadBotConfig(params.botid);
		if (botCfg == null) { trace("BLOCKED: botCfg is null"); return; }
		trace("botCfg: bot_id=" + botCfg.bot_id + " type=" + botCfg.bot_type + " prize=" + botCfg.prize_obj_id + " money=" + botCfg.money_reward);

		
		var botItems   = loadBotItems(params.botid);
		var needsStr   = buildNeedsString(botItems);
		var invResult  = removeFromInventory(store, params.id);

		// Get item name from cc_invlist for response
		var invlistRes = dbSelect("cc_invlist", ["name", "description"], {objID: params.id});
		var namee = "";
		if (invlistRes != null && invlistRes.size() > 0)
		{
			namee = invlistRes.get(0).getItem("name");
		}

		// --- Simple bot ---
		if (botCfg.bot_type == "simple")
		{
			if (invtrick.indexOf("," + params.id) != -1)
			{
				// did i already got this?
				var resp = {};
				resp._cmd = "sceneRep";
				resp.sub = "puz";
				resp.nowant = "0";
				_server.sendResponse(resp, -1, null, [user], "xml");
			}
			else if (needsStr.indexOf("," + params.id + ",") != -1 && invtrick.indexOf("," + params.id) == -1)
			{
				// is this useful?
				var addin = appendToList(invars, params.id);
				
				var resp = {};
				resp._cmd = "sceneRep";
				resp.sub = "puz";
				resp.invvar = addin;
				resp.di = params.id;
				resp.nw = "1";
				resp.win = "1";
				resp.botid = params.botid;
				_server.sendResponse(resp, -1, null, [user], "xml");

				dbSaveUserField(username, "invars", addin);

				// Simple bots: always remove from inventory and give reward
				var resp = {};
				resp._cmd = "dinv";
				resp.id = params.id;
				_server.sendResponse(resp, -1, null, [user], "xml");

				if (invResult.found)
				{
					dbSaveUserField(username, "inventory", invResult.newStore);
				}

				moneyDB(user, fromRoom, "+", botCfg.money_reward);
			}
		}

		// --- Complex bot ---
		if (botCfg.bot_type == "complex")
		{
			if (needsStr.indexOf("," + params.id + ",") == -1)
			{
				// is this useful?
				var resp = {};
				resp._cmd = "sceneRep";
				resp.sub = "puz";
				resp.nowant = "1";
				_server.sendResponse(resp, -1, null, [user], "xml");
			}
			else if (invtrick1.indexOf("," + params.id + ",") != -1)
			{
				// did i already got this?
				var resp = {};
				resp._cmd = "sceneRep";
				resp.sub = "puz";
				resp.keep = "1";
				_server.sendResponse(resp, -1, null, [user], "xml");
			}
			else if (needsStr.indexOf("," + params.id + ",") != -1 && invtrick1.indexOf("," + params.id + ",") == -1)
			{
				// is this useful?
				if (invResult.found)
				{
					var resp = {};
					resp._cmd = "dinv";
					resp.id = params.id;
					_server.sendResponse(resp, -1, null, [user], "xml");

					dbSaveUserField(username, "inventory", invResult.newStore);
				}

				var addin = appendToList(invars, params.id);
				dbSaveUserField(username, "invars", addin);

				// read invars after save to check completion
				var freshInvars = dbGetUserField(username, "invars");
				var invtrick99 = "," + freshInvars;


				var remaining = [];
				for (var i = 0; i < botItems.length; i++)
				{
					if (botItems[i] != params.id)
					{
						remaining.push(botItems[i]);
					}
				}

				var check = true;
				for (var j = 0; j < remaining.length; j++)
				{
					if (invtrick99.indexOf("," + remaining[j]) == -1)
					{
						check = false;
						break;
					}
				}

				if (check)
				{
					var resp = {};
					resp._cmd = "sceneRep";
					resp.sub = "puz";
					resp.invvar = addin;
					resp.di = params.id;
					resp.win = "1";
					resp.nw = "1";
					resp.botid = params.botid;
					resp.nm = namee;
					_server.sendResponse(resp, -1, null, [user], "xml");

					var prizeObjId = botCfg.prize_obj_id;
					var reward = buildInvStringFromObjId(prizeObjId);
					if (reward == null) { trace("[BOT_give] prize item not found for objId: " + prizeObjId); return; }

					var resp = {};
					resp._cmd = "buy";
					resp.adinv = reward;
					_server.sendResponse(resp, -1, null, [user], "xml");

					// Re-read inventory after potential removal above
					var currentStore = dbGetUserField(username, "inventory");
					if (currentStore == null) currentStore = "";
					var additem = appendToInventory(currentStore, reward);
					dbSaveUserField(username, "inventory", additem);

					if (botCfg.money_reward > 0)
					{
						moneyDB(user, fromRoom, "+", botCfg.money_reward);
					}
				}
				else
				{
					var resp = {};
					resp._cmd = "sceneRep";
					resp.di = params.id;
					resp.sub = "puz";
					resp.botid = params.botid;
					resp.nm = namee;
					resp.invvar = addin;
					resp.nw = "1";
					_server.sendResponse(resp, -1, null, [user], "xml");
				}
			}
		}
	}

	// =============================================================
	// pzl - Puzzle item pickup (monkey/stone rooms)
	// =============================================================
	if (cmd == "pzl") {

		var invResult = removeFromInventory(store, params.id);

		if (invResult.found)
		{
			dbSaveUserField(username, "inventory", invResult.newStore);

			var resp = {};
			resp._cmd = "dinv";
			resp.id = params.id;
			_server.sendResponse(resp, -1, null, [user], "xml");
		}

		var addin = appendToList(invars, params.id);

		var resp = {};
		resp._cmd = "sceneRep";
		resp.invvar = addin;
		_server.sendResponse(resp, -1, null, [user], "xml");

		dbSaveUserField(username, "invars", addin);

		trace("params.id : " + params.id);

		// This fixes a bug from the original server
		// so any banana OID works on any monkey in the correct room.
		var pzlId = params.id; // fallback to item id if no mapping
		var currentRoomName = _server.getCurrentZone().getRoom(fromRoom).getName();
		var roomPzlRes = dbSelect("cc_monkey_rooms", ["pzl_id"], {room_name: currentRoomName});
		if (roomPzlRes != null && roomPzlRes.size() > 0)
		{
			var roomPzlVal = roomPzlRes.get(0).getItem("pzl_id");
			if (roomPzlVal != null && roomPzlVal != "") pzlId = roomPzlVal;
		}
		else
		{
			// not a monkey puzzle, try item-based lookup for non-monkey puzzle items
			var pzlRes = dbSelect("cc_invlist", ["pzl_id"], {objID: params.id});
			if (pzlRes != null && pzlRes.size() > 0)
			{
				var pzlVal = pzlRes.get(0).getItem("pzl_id");
				if (pzlVal != null && pzlVal != "") pzlId = pzlVal;
			}
		}

		// Cheat detection: block if puzzle already solved
		if (pzlAlreadyClaimed(pvars, pzlId))
		{
			trace("[pzl] CHEAT DETECTED: " + username + " tried to claim already-solved puzzle id=" + pzlId);
			return;
		}

		var addmonky = appendToList(pvars, pzlId);

		var resp = {};
		resp._cmd = "sceneRep";
		resp.sub = "puz";
		resp.id = pzlId;
		resp.pzlupd = addmonky;
		_server.sendResponse(resp, -1, null, [user], "xml");

		dbSaveUserField(username, "pzl", addmonky);
	}

	//that dude in the battle zone
	if (cmd == "bribe") {

		var bribeData = dbGetUserData(username, ["money", "tribe_id"]);
		if (bribeData == null) return;

		var cr    = bribeData.money;
		var tribe = bribeData.tribe_id;

		var zone  = _server.getCurrentZone();
		var room  = zone.getRoom(fromRoom);
		var value = "0";
		if (room != null)
		{
			var tbVar = room.getVariable("tb");
			if (tbVar != null) value = tbVar.getValue();
		}

		var parts  = cr.split(",");
		var yeknom = parts[0];
		var huhulo = parts[1];

		var m;
		if (value == "1" || tribe == "1" && value == "0") m = yeknom;
		if (value == "2" || tribe == "2" && value == "0") m = huhulo;

		var bribePrice = Number(loadPuzzleConfig("bribe_price"));
		if (isNaN(bribePrice)) bribePrice = 50;

		var crNum = Number(m);
		var opi   = crNum - bribePrice;

		var resp = {};
		resp._cmd = "sceneRep";
		resp.sub  = "bribe";
		if (crNum >= bribePrice) resp.res = "1";
		else resp.res = "0";

		_server.sendResponse(resp, -1, null, [user], "xml");

		if (resp.res == "1")
		{
			var save;
			if (value == "1" || tribe == "1" && value == "0") save = opi + "," + huhulo;
			if (value == "2" || tribe == "2" && value == "0") save = yeknom + "," + opi;

			dbSaveUserField(username, "money", save);

			var resp = {};
			resp._cmd = "purse";
			resp.cr = save;
			_server.sendResponse(resp, -1, null, [user], "xml");
		}
	}

	// =============================================================
	// claimreward - Claim puzzle rewards
	// =============================================================
	if (cmd == "claimreward") {

		anti_hackers(user);

		// Load all rewards for this room
		var roomRewards = loadRoomRewards(fromRoom);
		if (roomRewards.length == 0) return;

		// Find matching reward config
		var reward = null;
		for (var i = 0; i < roomRewards.length; i++)
		{
			var rw = roomRewards[i];
			// Match by choice_id if present, or take null-choice reward
			if (rw.choice_id == params.id || (rw.choice_id == null && params.id == null))
			{
				reward = rw;
				break;
			}
			// For rooms with no choice (choice_id is NULL in DB), match any params.id
			if (rw.choice_id == null || rw.choice_id == "")
			{
				reward = rw;
				break;
			}
		}

		if (reward == null) return;

		var theid = reward.pzl_id;

		// Cheat detection: block if reward already claimed
		// TODO:AC
		if (pzlAlreadyClaimed(pvars, theid))
		{
			trace("[claimreward] CHEAT DETECTED: " + username + " tried to claim already-claimed reward pzl_id=" + theid);
			return;
		}

		// --- special_gem: remove item, give money, update invars ---
		if (reward.reward_type == "special_gem")
		{
			var removeId = reward.remove_item_obj_id;
			var invResult = removeFromInventory(store, removeId);

			if (invResult.found)
			{
				dbSaveUserField(username, "inventory", invResult.newStore);

				var resp = {};
				resp._cmd = "dinv";
				resp.id = "" + removeId;
				_server.sendResponse(resp, -1, null, [user], "xml");

				var addpzl = appendToList(pvars, theid);

				var resp = {};
				resp._cmd = "sceneRep";
				resp.sub = "puz";
				resp.pzlupd = addpzl;
				_server.sendResponse(resp, -1, null, [user], "xml");

				dbSaveUserField(username, "pzl", addpzl);

				moneyDB(user, fromRoom, "+", reward.money_amount);

				if (reward.add_invars_id != null)
				{
					var addgem = appendToList(invars, reward.add_invars_id);
					dbSaveUserField(username, "invars", addgem);
				}
			}
			return;
		}

		// --- money: just give coins ---
		if (reward.reward_type == "money")
		{
			moneyDB(user, fromRoom, "+", reward.money_amount);

			var addpzl = appendToList(pvars, theid);
			dbSaveUserField(username, "pzl", addpzl);

			var resp = {};
			resp._cmd = "sceneRep";
			resp.id = theid;
			resp.sub = "puz";
			resp.pzlupd = addpzl;
			_server.sendResponse(resp, -1, null, [user], "xml");
			return;
		}

		// --- item: give item (tribe rescue hat choice 1) ---
		if (reward.reward_type == "item")
		{
			var itemObjId = reward.item_obj_id;
			var item = buildInvStringFromObjId(itemObjId);
			if (item == null) { trace("[claimreward] item not found for objId: " + itemObjId); return; }

			var resp = {};
			resp._cmd = "buy";
			resp.adinv = item;
			_server.sendResponse(resp, -1, null, [user], "xml");

			var additem = appendToInventory(store, item);

			// Tutorial island: skip sceneRep sub=puz (it resets client to fish step),
			// consume the horn, and save invars instead.
			if (fromRoom == 36)
			{
				if (reward.remove_item_obj_id != null && reward.remove_item_obj_id != "")
				{
					var remResult = removeFromInventory(additem, reward.remove_item_obj_id);
					if (remResult.found)
					{
						additem = remResult.newStore;
						var resp = {};
						resp._cmd = "dinv";
						resp.id = "" + reward.remove_item_obj_id;
						_server.sendResponse(resp, -1, null, [user], "xml");
					}
				}
				dbSaveUserField(username, "inventory", additem);
				if (reward.add_invars_id != null && reward.add_invars_id != "")
				{
					dbSaveUserField(username, "invars", appendToList(invars, reward.add_invars_id));
				}
				dbSaveUserField(username, "pzl", appendToList(pvars, theid));
				return;
			}

			dbSaveUserField(username, "inventory", additem);

			var addpzl = appendToList(pvars, theid);

			var resp = {};
			resp._cmd = "sceneRep";
			resp.id = theid;
			resp.sub = "puz";
			resp.pzlupd = addpzl;
			_server.sendResponse(resp, -1, null, [user], "xml");

			dbSaveUserField(username, "pzl", addpzl);
			return;
		}

		// --- item_or_money: tribe rescue with choice (rooms 8/15) ---
		// Handled above via separate rows with choice_id "1" (item) and "2" (money)

		// --- both: give item + money (beach) ---
		if (reward.reward_type == "both")
		{
			moneyDB(user, fromRoom, "+", reward.money_amount);

			var itemObjId = reward.item_obj_id;
			var item = buildInvStringFromObjId(itemObjId);
			if (item == null) { trace("[claimreward] item not found for objId: " + itemObjId); return; }

			var resp = {};
			resp._cmd = "buy";
			resp.adinv = item;
			_server.sendResponse(resp, -1, null, [user], "xml");

			var additem = appendToInventory(store, item);
			dbSaveUserField(username, "inventory", additem);

			var addpzl = appendToList(pvars, theid);
			dbSaveUserField(username, "pzl", addpzl);

			var resp = {};
			resp._cmd = "sceneRep";
			resp.id = theid;
			resp.sub = "puz";
			resp.pzlupd = addpzl;
			_server.sendResponse(resp, -1, null, [user], "xml");
			return;
		}
	}

	// =============================================================
	// energy - Buy energy
	// =============================================================
	if (cmd == "energy") {

		var price = loadEnergyPrice(params.id);
		if (price == null) return;

		var result = moneyDB(user, fromRoom, "-", price);
		if (result == null)
		{
			var resp  = {};
			resp._cmd = "popupReply";
			resp.popup = "store";
			resp.sub  = "noCurrency";
			_server.sendResponse(resp, -1, null, [user], "xml");
		}
	}

	// =============================================================
	// tuberide - tube ride
	// =============================================================
	if (cmd == "tuberide") {

		var tierId = Number(params.id);
		if (isNaN(tierId) || tierId < 1 || tierId > 3) { trace("[tuberide] BLOCKED invalid tier: " + params.id); return; }

		var price = loadTuberidePrice(tierId);
		if (price == null) { trace("[tuberide] No price found for tier: " + tierId); return; }

		var result = moneyDB(user, fromRoom, "-", price);
		if (result == null)
		{
			var resp  = {};
			resp._cmd = "popupReply";
			resp.popup = "store";
			resp.sub  = "noCurrency";
			_server.sendResponse(resp, -1, null, [user], "xml");
		}
	}

	// =============================================================
	// pzldrp - Puzzle item drop
	// =============================================================
	if (cmd == "pzldrp") {

		var invResult = removeFromInventory(store, params.id);

		if (invResult.found)
		{
			dbSaveUserField(username, "inventory", invResult.newStore);

			var resp = {};
			resp._cmd = "dinv";
			resp.id = params.id;
			_server.sendResponse(resp, -1, null, [user], "xml");
		}

		var addin = appendToList(invars, params.id);
		dbSaveUserField(username, "invars", addin);

		var resp = {};
		resp._cmd = "sceneRep";
		resp.id = params.id;
		resp.sub = "puz";
		resp.invvar = addin;
		_server.sendResponse(resp, -1, null, [user], "xml");
	}

	// =============================================================
	// scrt - Secret door
	// =============================================================
    if (cmd == "scrt") {
	
		var z = _server.getCurrentZone();
		var r = z.getRoom(fromRoom);
		var open = 1;
		var rVars = [];
		rVars.push( {name:"door", val:open, priv:false, persistent:false} );
		_server.setRoomVariables(r, null, rVars);

		var prm = {};
		prm.r = r;
		prm.user = username;

		counter[username] = setInterval("wait", 13000, prm);
	}

	// =============================================================
	// doneTutorial
	// =============================================================
	if (cmd == "doneTutorial")
	{
		dbSaveUserField(username, "dotutorial", "0");

		var resp = {};
		resp._cmd = "sceneRep";
		resp.tutorialCompl = "1";
		_server.sendResponse(resp, -1, null, [user], "xml");
	}
}

// ---------------------------------------------------------
// Timer callback: close secret door
// ---------------------------------------------------------
function wait(prm)
{    
     var close = 0;
     var rVars = [];
     rVars.push( {name:"door", val:close, priv:false, persistent:false} );
     _server.setRoomVariables(prm.r, null, rVars);

	 clearInterval(counter[prm.user]);
	 delete counter[prm.user];

     return;
}

// ---------------------------------------------------------
// moneyDB - Handle tribe-aware currency operations
// Returns the new money string on success, or null if the player
// cannot afford the deduction (math == "-" and balance < cost).
// ---------------------------------------------------------
function moneyDB(user, fromRoom, math, valu)
{
    var username = user.getName();
	var data = dbGetUserData(username, ["money", "tribe_id"]);

	var cr = "";
	var tribe = "";
	if (data != null)
	{
		cr    = data.money;
		tribe = data.tribe_id;
	}

    var zone = _server.getCurrentZone();
	var room = zone.getRoom(fromRoom);
	var value = "0";
	
	if (room != null) {
		var tbVar = room.getVariable("tb");
		if (tbVar != null) {
			value = tbVar.getValue();
		}
	}
	
	var parts  = cr.split(",");
    var yeknom = parts[0];
    var huhulo = parts[1];
	
	if (value == "1" || tribe == "1" && value == "0") var moneyy = yeknom;
    if (value == "2" || tribe == "2" && value == "0") var moneyy = huhulo;
	
    var much  = Number(valu);
	var money = Number(moneyy);

	if (math == "-" && money < much)
	{
		trace("[moneyDB] BLOCKED: " + username + " cannot afford " + much + " (has " + money + ")");
		return null;
	}

	if (math == "+") var opiration = (money + much);
	if (math == "-") var opiration = (money - much);
	if (math == "*") var opiration = (money * much);
	if (math == "/") var opiration = (money / much);
	
	var save = cr;

    if (value == "1" || tribe == "1" && value == "0") save = opiration + "," + huhulo;
    if (value == "2" || tribe == "2" && value == "0") save = yeknom + "," + opiration;
    
	dbSaveUserField(username, "money", save);
	
	var resp = {};
	resp._cmd = "purse";
    resp.cr = save;
	_server.sendResponse(resp, -1, null, [user], "xml");
	
	return save;
}

// ---------------------------------------------------------
// Anti-hack: detect rapid-fire requests
// ---------------------------------------------------------
function anti_hackers(user)
{
    var username = user.getName();
    var ary = antihack.username;
    if (ary == undefined) ary = antihack.username = [];
		
    if (user != null) 
    {   
        ary.push(getTimer());
        var thetime = ary.slice(Math.max(ary.length - 2, 1));
		
        if (thetime.length == 2)
        {
            if (thetime[1] - thetime[0] <= 100)
            {
			    var lan = user.properties.get("lang");
                if (lan != null) var lang = lan;
					
                if (lang == "1") var msg = "لقد تم حظرك لمحاولتك استعمال برنامج الويب برو";
                if (lang == "0") var msg = "You're being banned Because you tried to use Web Pro";
                var ban = _server.banUser(user, 1, msg, _server.BAN_BY_NAME);
             
                delete antihack.username;
            }
        }
    }
}

// ---------------------------------------------------------
// Utility: format current date as YYYY-M-D
// ---------------------------------------------------------
function fulldate()
{
    var date = new Date();
    var month = date.getMonth() + 1;
    var year = date.getFullYear();
    var str = date.toString();
    var spl = str.split(" ");
    var day = spl[2];
    var full = year + "-" + month + "-" + day;
    return full;
}