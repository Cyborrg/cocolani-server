// =====================================================
// main.as  –  Cocolani core extension
// ------------------------------------------------------------------

function init()
{
}

function destroy()
{
}

// =========================================================
// MAIN REQUEST HANDLER
// =========================================================
function handleRequest(cmd, params, user, fromRoom)
{
	trace("cmd received: " + cmd);

	var username = user.getName();
	var zone     = _server.getCurrentZone();
	var r        = zone.getRoom(fromRoom);

	// ---------------------------------------------------------
	// wlk - Walk / movement destination
	// ---------------------------------------------------------
	if (cmd == "wlk")
	{
		trace("wlk : " + params.v);
		var v = params.v;
		if (v != undefined)
		{
			var uVars = {};
			if (v.dst != undefined) uVars.dst = String(v.dst);
			uVars.pth = (v.pth != undefined) ? v.pth : 1;
			_server.setUserVariables(user, uVars, true);
		}
	}

	// ---------------------------------------------------------
	// mov - Snap position update
	// ---------------------------------------------------------
	else if (cmd == "mov")
	{
		trace("mov : " + params.ps);
		var ps = params.ps;
		if (ps != undefined)
		{
			var uVars = {};
			uVars.ps  = String(ps);
			// This might be confusing but here is why
			// We should store server-side only. Broadcasting ps triggers
			// initStartPos() on observers which calls stopwalk(), this kills
			// the walkto() animation started by the wlk dst update. The stored
			// ps still appears in joinOK for late-joining players.
			_server.setUserVariables(user, uVars, false);
		}
	}

	// ---------------------------------------------------------
	// act - Play an animation / emote
	// ---------------------------------------------------------
	else if (cmd == "act")
	{
		var resp  = {};
		resp._cmd = "action";
		resp.usr  = user.getUserId();
		resp.act  = params.id;
		if (params.ps != undefined) resp.ps = params.ps;
		_server.sendResponse(resp, -1, null, getPlayersInRoom(user, r));
	}

	// ---------------------------------------------------------
	// sit - Sit on / stand from a seat object
	// ---------------------------------------------------------
	else if (cmd == "sit")
	{
		var t     = params.t;
		var uVars = {};
		if (t == undefined || t == null)
		{
			uVars.stsid = null;
			uVars.stob  = null;
		}
		else
		{
			uVars.stsid = t.stsid;
			uVars.stob  = t.stob;
		}
		_server.setUserVariables(user, uVars, true);
	}

	// ---------------------------------------------------------
	// setBusy - Mark user as busy/idle
	// ---------------------------------------------------------
	else if (cmd == "setBusy")
	{
		var isBusy = false;
		for (var k in params) { isBusy = true; break; }
		var uVars    = {};
		uVars.isBusy = isBusy;
		_server.setUserVariables(user, uVars, true);
	}

	// ---------------------------------------------------------
	// getUserCounts - Population count per tribe for the map
	// ---------------------------------------------------------
	else if (cmd == "getUserCounts")
	{
		var tribeN    = Number(getRoomVar(r, "tb"));
		var data      = [];
		var t1Count   = 0;
		var t2Count   = 0;
		var zoneUsers = zone.getUserList();
		for (var i = 0; i < zoneUsers.size(); i++)
		{
			var zu    = zoneUsers.get(i);
			var zuTb  = Number(zu.getVariable("tb"));
			if      (zuTb == 1) t1Count++;
			else if (zuTb == 2) t2Count++;
		}

		if (tribeN == 1)
		{
			// In tribe-1 territory: tribe-1 are locals, tribe-2 are visitors
			data.push(String(t1Count));
			data.push(String(t2Count));
		}
		else if (tribeN == 2)
		{
			// In tribe-2 territory: tribe-2 are locals, tribe-1 are visitors
			data.push(String(t2Count));
			data.push(String(t1Count));
		}
		else
		{
			// Neutral / battle zone – show both raw counts
			data.push(String(t1Count));
			data.push(String(t2Count));
		}

		var resp  = {};
		resp._cmd = "interface";
		resp.sub  = "mapResponse";
		resp.data = data;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// getChief - Get the name of the tribe chief
	// ---------------------------------------------------------
	else if (cmd == "getChief")
	{
		var tbId  = (fromRoom == 17) ? 2 : 1;
		var resp  = {};
		resp._cmd = "sceneRep";
		resp.sub  = "chief";
		resp.nm   = getChiefName(tbId);
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// profile - View another user's public profile
	// ---------------------------------------------------------
	else if (cmd == "profile")
	{
		if (!isValidInt(params.id)) { trace("BLOCKED: invalid profile id"); return; }

		var targetUser = _server.getUserById(Number(params.id));
		if (targetUser == null) return;

		var pData = dbGetUserData(targetUser.getName(),
			["about", "register_date", "skill", "gam", "homeAddr", "medals", "btl"]);
		if (pData == null) return;

		var resp  = {};
		resp._cmd = "profile";
		resp.abt  = pData.about;
		resp.rdt  = pData.register_date;
		resp.skl  = pData.skill;
		resp.gam  = pData.gam;
		resp.med  = String(pData.medals).split(",");
		resp.btl  = String(pData.btl).split(";");
		if (Number(pData.homeAddr) != -1) resp.hom = pData.homeAddr;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// buyINV - Purchase an item from a store or picked it up
	// ---------------------------------------------------------
	else if (cmd == "buyINV")
	{
		if (!isValidInt(params.objid)) { trace("BLOCKED: invalid objid"); return; }

		var itemObjId = params.objid;
		var item      = buildInvStringFromObjId(itemObjId);
		if (item == null) { trace("[buyINV] item not found: " + itemObjId); return; }

		var priceRow = dbSelect("cc_invlist", ["price", "type", "weaponStore", "H_ClothStore", "Y_ClothStore", "H_FurnStore", "Y_FurnStore"], {objID: itemObjId});
		if (priceRow == null || priceRow.size() == 0) return;
		var price   = Number(priceRow.get(0).getItem("price"));
		var objType = Number(priceRow.get(0).getItem("type"));


		if (objType != 0)
		{
			var inStore = (priceRow.get(0).getItem("weaponStore") != "0" ||
			               priceRow.get(0).getItem("H_ClothStore") != "0" ||
			               priceRow.get(0).getItem("Y_ClothStore") != "0" ||
			               priceRow.get(0).getItem("H_FurnStore")  != "0" ||
						   priceRow.get(0).getItem("Y_BallonStore")  != "0" ||
						   priceRow.get(0).getItem("H_BallonStore")  != "0" ||
						   priceRow.get(0).getItem("tutStore")  != "0" ||
			               priceRow.get(0).getItem("Y_FurnStore")  != "0");
			if (!inStore) { trace("BLOCKED: item not in any store: " + itemObjId); return; }
		}

		if (price < 0) { trace("BLOCKED: negative price for objID " + itemObjId); return; }

		if (objType == 7)
		{
			var ownCheck = dbGetUserData(username, ["inventory"]);
			if (ownCheck != null)
			{
				var ownArr = ownCheck.inventory.split("|");
				for (var oi = 0; oi < ownArr.length; oi++)
				{
					if (ownArr[oi].split("~")[0] == String(itemObjId))
					{
						trace("BLOCKED: player already owns weapon " + itemObjId + ", use upgradeINV");
						return;
					}
				}
			}
		}

		var userData = dbGetUserData(username, ["money", "inventory"]);
		if (userData == null) return;

		var moneyArray = userData.money.split(",");
		var prevInv    = userData.inventory;
		var tribeN     = Number(getRoomVar(r, "tb"));

		if (objType != 0)
		{
			if ((tribeN == 1 && Number(moneyArray[0]) < price) ||
			    (tribeN == 2 && Number(moneyArray[1]) < price))
			{
				var resp   = {};
				resp._cmd  = "popupReply";
				resp.popup = "store";
				resp.sub   = "noCurrency";
				_server.sendResponse(resp, -1, null, [user]);
				return;
			}
			if (tribeN == 1)      moneyArray[0] = String(Number(moneyArray[0]) - price);
			else if (tribeN == 2) moneyArray[1] = String(Number(moneyArray[1]) - price);
		}

		var newMoney = moneyArray[0] + "," + moneyArray[1];
		dbSaveUserField(username, "money",     newMoney);
		dbSaveUserField(username, "happyness", "100");

		var newInv = appendToInventory(prevInv, item);
		dbSaveUserField(username, "inventory", newInv);

		var itemParts = item.split("~");

		var resp   = {};
		resp._cmd  = "buy";
		resp.hp    = "100";
		resp.cr    = newMoney;
		resp.adinv = item;
		resp.totalInv = newInv;
		_server.sendResponse(resp, -1, null, [user]);

		var resp4   = {};
		resp4._cmd   = "popupReply";
		resp4.popup  = "store";
		resp4.sub    = "storeSucccess";
		resp4.data   = [String(itemParts[2]), String(itemParts[4]), Number(price)];
		_server.sendResponse(resp4, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// setClth - Apply clothing loadout and persist to DB
	// ---------------------------------------------------------
	else if (cmd == "setClth")
	{
		var clthParts  = String(params.clthInvID).split(",");
		var translated = [];
		for (var i = 0; i < clthParts.length; i++)
		{
			var p = clthParts[i];
			if (p != "" && isValidUInt(p))
			{
				var rSwf = dbSelect("cc_invlist", ["swfID"], {objID: p});
				if (rSwf != null && rSwf.size() > 0)
					translated.push(rSwf.get(0).getItem("swfID"));
				else
				{
					translated.push(p);
					trace("[setClth] No swfID for objID " + p);
				}
			}
			else
			{
				translated.push("");
			}
		}
		var finalClth  = translated.join(",");
		var uVars      = {};
		uVars.clth     = finalClth;
		_server.setUserVariables(user, uVars, true);
		dbSaveUserField(username, "clothing", finalClth);
	}

	// ---------------------------------------------------------
	// updatePref - Save user UI preferences
	// ---------------------------------------------------------
	else if (cmd == "updatePref")
	{
		dbSaveUserField(username, "prefs", params.prefs);
	}

	// ---------------------------------------------------------
	// blurb - Update profile bio
	// ---------------------------------------------------------
	else if (cmd == "blurb")
	{
		dbSaveUserField(username, "about", params.val);
	}

	// ---------------------------------------------------------
	// getExchange - Return the current exchange rate
	// ---------------------------------------------------------
	else if (cmd == "getExchange")
	{
		var resp  = {};
		resp._cmd = "exchangeRt";
		resp.rt   = "1,1";
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// convertCurrency - Exchange coins between tribes
	// ---------------------------------------------------------
	else if (cmd == "convertCurrency")
	{
		if (!isValidInt(params.amt)) { trace("BLOCKED: invalid amt"); return; }

		var amt        = Number(params.amt);
		//TODO_AC: Antihack and ban user
		if (amt <= 0) { trace("BLOCKED: amt must be positive"); return; }

		var tribeN     = Number(getRoomVar(r, "tb"));
		var curMoney   = dbGetUserField(username, "money");
		if (curMoney == null) curMoney = "0,0";
		var moneyArray = curMoney.split(",");

		if (tribeN == 1 && Number(moneyArray[1]) < amt)
		{
			var resp   = {};
			resp._cmd  = "popupReply";
			resp.popup = "exchange";
			resp.sub   = "noCurrency";
			_server.sendResponse(resp, -1, null, [user]);
			return;
		}
		else if (tribeN == 2 && Number(moneyArray[0]) < amt)
		{
			var resp   = {};
			resp._cmd  = "popupReply";
			resp.popup = "exchange";
			resp.sub   = "noCurrency";
			_server.sendResponse(resp, -1, null, [user]);
			return;
		}

		if (tribeN == 1)
		{
			moneyArray[0] = String(Number(moneyArray[0]) + amt);
			moneyArray[1] = String(Number(moneyArray[1]) - amt);
		}
		else if (tribeN == 2)
		{
			moneyArray[1] = String(Number(moneyArray[1]) + amt);
			moneyArray[0] = String(Number(moneyArray[0]) - amt);
		}

		var newMoney = moneyArray[0] + "," + moneyArray[1];
		dbSaveUserField(username, "money", newMoney);

		var resp  = {};
		resp._cmd = "purse";
		resp.cr   = newMoney;
		_server.sendResponse(resp, -1, null, [user]);

		var resp2  = {};
		resp2._cmd  = "exchangeRsp";
		resp2.crfm  = (tribeN == 2) ? "0" : "1";
		resp2.crbt  = (tribeN == 2) ? "2" : "1";
		resp2.ambt  = amt;
		resp2.amfm  = amt;
		resp2.rt    = "1";
		resp2.cr    = newMoney;
		_server.sendResponse(resp2, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// getStoreItems - Load item list for a store popup
	// Weapon stores use a different field order in the response.
	// ---------------------------------------------------------
	else if (cmd == "getStoreItems")
	{
		var locID    = params.locID;
		var shopType = params.type;

		var storeCol     = null;
		var storeVal     = null;
		var weaponFormat = false;

		if      (locID == 15) { storeCol = "H_ClothStore"; storeVal = "15"; }
		else if (locID == 35) { storeCol = "H_FurnStore";  storeVal = "35"; }
		else if (locID ==  9) { storeCol = "Y_FurnStore";  storeVal = "9";  }
		else if (locID == 36) { storeCol = "tutStore";     storeVal = "36"; }
		else if (locID == -1) { storeCol = "weaponStore";  storeVal = "-1"; weaponFormat = true; }
		else if (locID ==  8)
		{
			if (shopType == "weapons") { storeCol = "weaponStore";  storeVal = "-1"; weaponFormat = true; }
			else                       { storeCol = "Y_ClothStore"; storeVal = "8"; }
		}

		var invlist = "";
		if (storeCol != null)
		{
			var where     = {};
			where[storeCol] = storeVal;
			var qRes = dbSelect("cc_invlist", "*", where);
			if (qRes != null)
			{
				for (var i = 0; i < qRes.size(); i++)
				{
					var row    = qRes.get(i);
					var oID    = Number(row.getItem("objID"));
					var oName  = row.getItem("name");
					var oDesc  = row.getItem("description");
					var oSwf   = Number(row.getItem("swfID"));
					var oPrice = Number(row.getItem("price"));
					var oKind  = Number(row.getItem("kind"));
					var oExch  = Number(row.getItem("exchange"));
					var oLvl   = row.getItem("lvl");
					var oType  = Number(row.getItem("type"));
					var oLast  = Number(row.getItem("LastNumber"));

					if (weaponFormat)
						invlist += oID+"|"+oName+"|"+oDesc+"|"+oSwf+"|"+oPrice+"|"+oKind+"|"+oLast+"|"+oLvl+"|"+oType+"|"+oExch+"%";
					else
						invlist += oID+"|"+oName+"|"+oDesc+"|"+oSwf+"|"+oPrice+"|"+oKind+"|"+oExch+"|"+oLvl+"|"+oType+"|"+oLast+"%";
				}
			}
		}

		var resp   = {};
		resp._cmd  = "popupReply";
		resp.popup = "store";
		resp.sub   = "storeInfo";
		resp.data  = invlist;
		_server.sendResponse(resp, -1, null, [user]);
	}

	// ---------------------------------------------------------
	// trade - Offer an inventory item to another player
	// ---------------------------------------------------------
	else if (cmd == "trade")
	{
		if (!isValidInt(params.id) || !isValidInt(params.uid))
		{
			trace("BLOCKED: invalid trade params");
			return;
		}

		var targetUser = _server.getUserById(Number(params.uid));
		if (targetUser == null) return;

		var item = buildInvStringFromObjId(params.id);
		if (item == null) return;

		var itemName   = item.split("~")[4];
		var senderLang = dbGetUserField(username, "lang_id");
		if (senderLang == null) senderLang = "0";

		var resp  = {};
		resp._cmd = "error";
		resp.err  = getMsg(senderLang,
			"You offered " + itemName + " to " + targetUser.getName(),
			"لقد عرضت " + itemName + " على " + targetUser.getName()
		);
		_server.sendResponse(resp, -1, null, [user]);

		var resp2  = {};
		resp2._cmd = "trdrq";
		resp2.inv  = item;
		resp2.uid  = Number(user.getUserId());
		_server.sendResponse(resp2, -1, null, [targetUser]);
	}

	// ---------------------------------------------------------
	// tradecnf - Accept or decline an incoming trade offer
	// ---------------------------------------------------------
	else if (cmd == "tradecnf")
	{
		if (!isValidInt(params.uid)) { trace("BLOCKED: invalid uid"); return; }

		var targetUser   = _server.getUserById(Number(params.uid));
		if (targetUser == null) return;

		var receiverName = username;
		var receiverLang = dbGetUserField(username, "lang_id");
		var senderLang   = dbGetUserField(targetUser.getName(), "lang_id");
		if (receiverLang == null) receiverLang = "0";
		if (senderLang   == null) senderLang   = "0";

		var accepted = params.rply;

		if (accepted == 0)
		{
			var resp  = {};
			resp._cmd = "error";
			resp.err  = getMsg(senderLang,
				receiverName + " declined your offer",
				"عرضك رفض من طرف " + receiverName
			);
			_server.sendResponse(resp, -1, null, [targetUser]);
		}
		else if (accepted == 1)
		{
			if (!isValidInt(params.id)) { trace("BLOCKED: invalid item id"); return; }

			var itemObjId = Number(params.id);
			var item      = buildInvStringFromObjId(itemObjId);
			if (item == null) return;
			var itemName  = item.split("~")[4];

			var receiverData = dbGetUserData(username, ["inventory"]);
			if (receiverData == null) return;
			var newReceiverInv = appendToInventory(receiverData.inventory, item);
			dbSaveUserField(username, "inventory", newReceiverInv);

			var resp1  = {};
			resp1._cmd = "error";
			resp1.err  = getMsg(receiverLang,
				"You received " + itemName + " from " + targetUser.getName(),
				"لقد استلمت " + itemName + " من " + targetUser.getName()
			);
			_server.sendResponse(resp1, -1, null, [user]);

			var resp2      = {};
			resp2._cmd     = "ginv";
			resp2.adinv    = item;
			resp2.totalInv = newReceiverInv;
			_server.sendResponse(resp2, -1, null, [user]);

			var senderData = dbGetUserData(targetUser.getName(), ["inventory"]);
			if (senderData != null)
			{
				var removal = removeFromInventory(senderData.inventory, String(itemObjId));
				if (removal.found)
					dbSaveUserField(targetUser.getName(), "inventory", removal.newStore);
			}

			var resp3  = {};
			resp3._cmd = "error";
			resp3.err  = getMsg(senderLang,
				receiverName + " accepted your offer",
				"لقد تم قبول عرضك بواسطة " + receiverName
			);
			_server.sendResponse(resp3, -1, null, [targetUser]);

			var resp4  = {};
			resp4._cmd = "dinv";
			resp4.id   = itemObjId;
			_server.sendResponse(resp4, -1, null, [targetUser]);
		}
	}

	// ---------------------------------------------------------
	// upgradeINV - Upgrade a battle item using cc_item_upgrades
	// All validation happens BEFORE any money is touched.
	// ---------------------------------------------------------
	else if (cmd == "upgradeINV")
	{
		if (!isValidInt(params.objid)) { trace("BLOCKED: invalid objid"); return; }

		var itemObjId = params.objid;

		var priceRow = dbSelect("cc_invlist", ["price", "type"], {objID: itemObjId});
		if (priceRow == null || priceRow.size() == 0) return;
		var price   = Number(priceRow.get(0).getItem("price"));
		var objType = Number(priceRow.get(0).getItem("type"));

		if (objType != 7) { trace("BLOCKED: upgradeINV on non-weapon type " + objType + " for objID " + itemObjId); return; }
		if (price < 0)    { trace("BLOCKED: negative price for objID " + itemObjId); return; }

		var userData  = dbGetUserData(username, ["money", "inventory"]);
		if (userData == null) return;

		var prevInv    = userData.inventory;
		var moneyArray = userData.money.split(",");
		var tribeN     = Number(getRoomVar(r, "tb"));

		var upgRows = dbSelect("cc_item_upgrades", ["from_lvl", "to_lvl"], {objID: itemObjId});
		if (upgRows == null || upgRows.size() == 0) { trace("BLOCKED: no upgrade path for objID " + itemObjId); return; }

		var invArr   = prevInv.split("|");
		var foundIdx = -1;
		var curLvl   = -1;
		for (var i = 0; i < invArr.length; i++)
		{
			var parts = invArr[i].split("~");
			// parts: [0]=objID [1]=objID [2]=swfID [3]=desc [4]=name [5]=type [6]=exch [7]=kind [8]=lvl
			if (parts[0] == String(itemObjId))
			{
				foundIdx = i;
				curLvl   = Number(parts[8]);
				break;
			}
		}
		if (foundIdx == -1) { trace("BLOCKED: player does not own item " + itemObjId); return; }

		var toLvl = -1;
		for (var j = 0; j < upgRows.size(); j++)
		{
			if (Number(upgRows.get(j).getItem("from_lvl")) == curLvl)
			{
				toLvl = Number(upgRows.get(j).getItem("to_lvl"));
				break;
			}
		}
		if (toLvl == -1) { trace("BLOCKED: item " + itemObjId + " already at max level " + curLvl); return; }

		if ((tribeN == 1 && Number(moneyArray[0]) < price) ||
		    (tribeN == 2 && Number(moneyArray[1]) < price))
		{
			var resp   = {};
			resp._cmd  = "popupReply";
			resp.popup = "store";
			resp.sub   = "noCurrency";
			_server.sendResponse(resp, -1, null, [user]);
			return;
		}

		if (tribeN == 1)      moneyArray[0] = String(Number(moneyArray[0]) - price);
		else if (tribeN == 2) moneyArray[1] = String(Number(moneyArray[1]) - price);

		var newMoney = moneyArray[0] + "," + moneyArray[1];
		dbSaveUserField(username, "money", newMoney);

		var upgParts = invArr[foundIdx].split("~");
		upgParts[8]  = String(toLvl);
		var newBall  = upgParts.join("~");
		invArr[foundIdx] = newBall;
		dbSaveUserField(username, "inventory", invArr.join("|"));

		var resp  = {};
		resp._cmd = "purse";
		resp.cr   = newMoney;
		_server.sendResponse(resp, -1, null, [user]);

		var resp2   = {};
		resp2._cmd  = "popupReply";
		resp2.popup = "store";
		resp2.sub   = "upgradeSuccess";
		resp2.cr    = newMoney;
		resp2.amt   = price;
		resp2.data  = newBall;
		_server.sendResponse(resp2, -1, null, [user]);
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
	var result = dbSelect("cc_user", fields, {username: username});
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
// INVENTORY HELPERS
// =========================================================

function appendToInventory(store, item)
{
	if (store != null && store.length != 0) return store + "|" + item;
	return item;
}

// Remove first occurrence of an item matching objID from
// pipe-separated inventory string.
// Returns {found: bool, newStore: string}
function removeFromInventory(store, objID)
{
	var result = {found: false, newStore: store};
	var arr    = String(store).split("|");
	for (var i = 0; i < arr.length; i++)
	{
		if (arr[i].split("~")[0] == objID)
		{
			arr.splice(i, 1);
			result.newStore = arr.join("|");
			result.found    = true;
			break;
		}
	}
	return result;
}

// Build inventory item string from cc_invlist row for objID.
// Format: objID~objID~swfID~desc~name~type~exchange~kind~lvl
function buildInvStringFromObjId(objId)
{
	if (objId == null || objId == "") return null;
	var res = dbSelect("cc_invlist",
		["objID", "swfID", "name", "description", "type", "exchange", "kind", "lvl"],
		{objID: objId});
	if (res == null || res.size() == 0) return null;
	var row  = res.get(0);
	var oid  = row.getItem("objID");
	var swf  = row.getItem("swfID");
	var name = row.getItem("name");
	var desc = row.getItem("description");
	var type = row.getItem("type");
	var exch = row.getItem("exchange");
	var kind = row.getItem("kind");
	var lvl  = row.getItem("lvl");
	return oid+"~"+oid+"~"+swf+"~"+desc+"~"+name+"~"+type+"~"+exch+"~"+kind+"~"+lvl;
}

// =========================================================
// GENERAL HELPERS
// =========================================================


// lang_id "0" = English, "1" = Arabic
function getMsg(lang, en, ar)
{
	return (lang == "1") ? ar : en;
}

function getPlayersInRoom(user, room)
{
	var all    = room.getAllUsers();
	var result = [];
	for (var u in all)
	{
		if (all[u].getName() != user.getName()) result.push(all[u]);
	}
	return result;
}


function getRoomVar(room, varName)
{
	var varObj = room.getVariable(varName);
	if (varObj == null) return null;
	return varObj.getValue();
}

function getChiefName(tribeID)
{
	var resT = dbSelect("cc_tribes", ["chief_id"], {ID: tribeID});
	if (resT == null || resT.size() == 0) return "Unknown";
	var chiefId = resT.get(0).getItem("chief_id");

	var resU = dbSelect("cc_user", ["username"], {id: chiefId});
	if (resU == null || resU.size() == 0) return "Unknown";
	return resU.get(0).getItem("username");
}
