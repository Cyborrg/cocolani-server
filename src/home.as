/* ============================================================================
// home.as - home system extension
// 
// handles: getRentalInfo, buyRent, home (exterior), door (open/close/lock),
// homeInterior (enter house), homeExit (leave interior)
// home furniture: drp (drop), edt (edit), get (get list)
// 
// Room naming: homeExterior_<street>_tb<tribe> / homeInterior_<addr>_tb<tribe>
// 
// data room var format per slot: doorState,userId,username
// Slots joined by "|"  e.g. "1,100,Player1|0,200,Player2|0,0,0"
// doorState: 0=closed  1=open  2=locked
// userId 0 + username "0" = empty slot
// ============================================================================
*/
var dbase;
var RENT_PRICE = 40; // price per month, per tribe currency

function init()
{
   dbase = _server.getDatabaseManager();
   trace("[home.as] Home extension initialised");
}

function destroy()
{
   delete dbase;

}

// ============================================================================
// Helper: Get the db user ID
// ============================================================================
function getDbUserId(user)
{
   var dbId = getAccountValue(user.getName(), "ID");
   return Number(dbId);

}

// ============================================================================
// COMMAND ROUTER
// ============================================================================
function handleRequest(cmd, params, user, fromRoom)
{
   trace("[home.as] cmd=" + cmd + " user=" + user.getName());
   var currentZone = _server.getCurrentZone();

   var r = currentZone.getRoom(fromRoom);

   if (cmd == "getRentalInfo")
   {
      cmdGetRentalInfo(user, r);

   }
   else if (cmd == "buyRent")
   {
      cmdBuyRent(user, r, params);

   }
   else if (cmd == "home")
   {
      cmdHome(user, r, params, fromRoom);

   }
   else if (cmd == "door")
   {
      cmdDoor(user, r, params);

   }
   else if (cmd == "homeInterior")
   {
      cmdHomeInterior(user, r, params, fromRoom);

   }
   else if (cmd == "homeExit")
   {
      cmdHomeExit(user, r, params, fromRoom);

   }
   else if (cmd == "getMail")
   {
      cmdGetMail(user, r);

   }
   else if (cmd == "sendMail")
   {
      cmdSendMail(user, r, params);

   }
   else if (cmd == "read")
   {
      cmdReadMail(user, r, params);

   }
   else if (cmd == "drp")
   {
      cmdDropFurniture(user, r, params);

   }
   else if (cmd == "edt")
   {
      cmdEditFurniture(user, r, params);

   }
   else if (cmd == "get")
   {
      cmdGetFurniture(user, r, params);

   }
}

function handleInternalEvent(evt)
{
}

// ============================================================================
// getRentalInfo  -  Return rental status for current user
// ============================================================================
function cmdGetRentalInfo(user, room)
{
   var responseObj = {};

   responseObj._cmd = "sceneRep";

   responseObj.sub = "rentalData";

   responseObj.prc = String(RENT_PRICE);

   var dbId = getDbUserId(user);

   var homeAddr = getAccountValue(user.getName(), "homeAddr");

   if (homeAddr != null && homeAddr != "" && homeAddr != "-1")
   {
      // User has a home - fetch rental info from cc_homes
      var sql = "SELECT * FROM cc_homes WHERE user_id=" + dbId;

      var qr = dbase.executeQuery(sql);

      if (qr != null && qr.size() > 0)
      {
         var row = qr.get (0);

         responseObj.home_crt = row.getItem("created");

         responseObj.home_exp = row.getItem("expiry_date");

         responseObj.day = row.getItem("home_rental_period_days");

      }
      else
      {
         responseObj.home_crt = "";

         responseObj.home_exp = "";

         responseObj.day = "30";

      }
   }
   else
   {
      // No home
      responseObj.home_crt = "";

      responseObj.home_exp = "";

      responseObj.day = "30";

   }

   _server.sendResponse(responseObj, -1, null, [user]);

}

// ============================================================================
// buyRent  -  Purchase / rent a new home
// ============================================================================
function cmdBuyRent(user, room, params)
{
   var username = user.getName();

   var dbId = getDbUserId(user);


   // --- Check if player already owns a home ---
   var checkHasHome = getAccountValue(username, "homeAddr");

   if (checkHasHome != null && checkHasHome != "" && checkHasHome != "-1")
   {
      var errObj = {};

      errObj._cmd = "error";

      errObj.err = "You already own a home.";

      _server.sendResponse(errObj, -1, null, [user]);

      return;

   }

   // --- Determine tribe ---
   var playerTribe = getRoomVar(room, "tb");

   if (playerTribe == undefined || playerTribe == null)
      playerTribe = "1";

   playerTribe = String(playerTribe);

   // --- Number of months ---
   var NOM = Number(params.amt);

   if (isNaN(NOM) || NOM < 1)
      NOM = 1;

   // --- Deduct money ---
   var totalCost = RENT_PRICE * NOM;

   var playerMoney = getAccountValue(username, "money");

   if (playerMoney == null || playerMoney == "")
      playerMoney = "0,0";

   var moneyArray = playerMoney.split(",");

   var coin1 = Number(moneyArray[0]);
   var coin2 = Number(moneyArray[1]);
   if (isNaN(coin1) || coin1 < 0) coin1 = 0;
   if (isNaN(coin2) || coin2 < 0) coin2 = 0;

   var tribeNum = Number(playerTribe);

   if (tribeNum == 1)
   {
      if (coin1 < totalCost)
      {
         var nfObj = {};
         nfObj._cmd = "error";
         nfObj.err = "Not enough coins.";
         _server.sendResponse(nfObj, -1, null, [user]);
         return;
      }
      coin1 -= totalCost;
   }
   else if (tribeNum == 2)
   {
      if (coin2 < totalCost)
      {
         var nfObj = {};
         nfObj._cmd = "error";
         nfObj.err = "Not enough coins.";
         _server.sendResponse(nfObj, -1, null, [user]);
         return;
      }
      coin2 -= totalCost;
   }
   else
   {
      trace("[home.as] buyRent: unknown tribe " + playerTribe + " for user " + username);
      return;
   }

   var newMoney = String(coin1) + "," + String(coin2);

   setAccountValue(username, "money", newMoney);

   // --- Send purse update ---
   var purseObj = {};

   purseObj._cmd = "purse";

   purseObj.cr = newMoney;

   _server.sendResponse(purseObj, -1, null, [user]);

   // --- Compute dates ---
   var today = new Date();

   var dd = String(today.getDate());

   var mm = String(today.getMonth() + 1);

   var yyyy = today.getFullYear();

   var created = yyyy + "/" + mm + "/" + dd;

   var expMM = today.getMonth() + 1 + NOM;

   var expYYYY = yyyy;

   while (expMM > 12)
   {
      expMM -= 12;

      expYYYY += 1;

   }
   var expDate = expYYYY + "/" + expMM + "/" + dd;

   var rentalDays = 30 * NOM;

   // --- Find the next available slot for this tribe ---
   var sqlSlot = "SELECT street_num, COUNT(*) as cnt FROM cc_homes WHERE tribe_ID=" + playerTribe + " GROUP BY street_num ORDER BY street_num ASC";

   var qrSlot = dbase.executeQuery(sqlSlot);

   var assignedStreet = -1;

   var assignedSlot = -1;

   if (qrSlot != null && qrSlot.size() > 0)
   {
      for (var i = 0; i < qrSlot.size(); i++)
      {
         var sRow = qrSlot.get (i);

         var cnt = Number(sRow.getItem("cnt"));

         if (cnt < 3)
         {
            assignedStreet = Number(sRow.getItem("street_num"));

            break;

         }
      }
   }

   if (assignedStreet == -1)
   {
      var sqlMax = "SELECT MAX(CAST(street_num AS UNSIGNED)) as mx FROM cc_homes WHERE tribe_ID=" + playerTribe;

      var qrMax = dbase.executeQuery(sqlMax);

      if (qrMax != null && qrMax.size() > 0)
      {
         var maxVal = qrMax.get (0).getItem("mx");

         if (maxVal == null || maxVal == "")
         {
            assignedStreet = 1;

         }
         else
         {
            assignedStreet = Number(maxVal) + 1;

         }
      }
      else
      {
         assignedStreet = 1;

      }
   }

   // Find which slots (1-3) are taken on that street
   var sqlUsed = "SELECT slot FROM cc_homes WHERE tribe_ID=" + playerTribe + " AND street_num=" + assignedStreet + " ORDER BY slot ASC";

   var qrUsed = dbase.executeQuery(sqlUsed);

   var usedSlots = {};

   if (qrUsed != null)
   {
      for (var j = 0; j < qrUsed.size(); j++)
      {
         usedSlots[String(qrUsed.get (j).getItem("slot"))] = true;

      }
   }
   for (var s = 1; s <= 3; s++)
   {
      if (!usedSlots[String(s)])
      {
         assignedSlot = s;

         break;

      }
   }

   // --- Compute global homeAddr ---
   var homeAddr = (assignedStreet - 1) * 3 + assignedSlot;

   var sqlInsert = "INSERT INTO cc_homes (user_id, tribe_ID, street_num, slot, door_state, created, expiry_date, home_rental_period_days, max_street)";

   sqlInsert += " VALUES (" + dbId + ", " + playerTribe + ", " + assignedStreet + ", " + assignedSlot + ", '0', '" + created + "', '" + expDate + "', " + rentalDays + ", " + assignedStreet + ")";

   trace("[home.as] INSERT: " + sqlInsert);

   dbase.executeCommand(sqlInsert);

   setAccountValue(username, "homeAddr", String(homeAddr));

   setAccountValue(username, "home_ID", String(homeAddr));

   var checkStatus = getAccountValue(username, "status_ID");

   if (Number(checkStatus) == 3)
   {
      setAccountValue(username, "status_ID", "4");

      var uVars = {};

      uVars.usr = 4;

      _server.setUserVariables(user, uVars, true);

   }

   // --- Send response to client ---
   var responseObj = {};

   responseObj._cmd = "sceneRep";

   responseObj.sub = "homePurchase";

   responseObj.cr = newMoney;

   responseObj.street = String(homeAddr);

   responseObj.isnew = "1";

   responseObj.uLevel = "4";

   _server.sendResponse(responseObj, -1, null, [user]);

}

// ============================================================================
// home  -  Navigate to home exterior OR interior
// Client sends: cmd="home", params.hid=homeAddr, params.tid=tribeID
// params.ins=1 means enter the interior (inside the house)
// ============================================================================
function cmdHome(user, room, params, fromRoom)
{
   var username = user.getName();

   // --- Determine which home address and tribe to load ---
   var homeAddr = null;

   var playerTribe = null;

   var goInside = false;

   if (params != null && params.hid != undefined)
   {
      homeAddr = Number(params.hid);

   }
   if (params != null && params.tid != undefined)
   {
      playerTribe = String(params.tid);

   }
   if (params != null && params.ins != undefined)
   {
      goInside = (params.ins == 1 || params.ins == true || params.ins == "1");

   }

   if (homeAddr == null || isNaN(homeAddr) || homeAddr < 1)
   {
      homeAddr = Number(getAccountValue(username, "homeAddr"));

   }
   if (homeAddr == null || isNaN(homeAddr) || homeAddr < 1 || homeAddr == -1)
   {
      var errObj = {};

      errObj._cmd = "error";

      errObj.err = "You don't own a home yet.";

      _server.sendResponse(errObj, -1, null, [user]);

      return;

   }

   if (playerTribe == null || playerTribe == "" || playerTribe == "0")
   {
      var snFallback = Math.ceil(homeAddr / 3);

      var slFallback = ((homeAddr - 1) % 3) + 1;

      var sqlTribeFallback = "SELECT tribe_ID FROM cc_homes WHERE street_num=" + snFallback + " AND slot=" + slFallback + " ORDER BY ID ASC LIMIT 1";

      var qrTribeFallback = dbase.executeQuery(sqlTribeFallback);

      if (qrTribeFallback != null && qrTribeFallback.size() > 0)
         playerTribe = String(qrTribeFallback.get (0).getItem("tribe_ID"));

   }
   if (playerTribe == null || playerTribe == "")
      playerTribe = "1";

   var streetNum = Math.ceil(homeAddr / 3);

   trace("[home.as] home cmd: hid=" + homeAddr + " tid=" + playerTribe + " ins=" + goInside + " fromRoom=" + fromRoom);

   // =====================================================================
   // INTERIOR MODE: Create/join an interior room for a specific home slot
   // =====================================================================
   if (goInside)
   {
      var intRoomName = "homeInterior_" + homeAddr + "_tb" + playerTribe;

      trace("[home.as] interior: roomName=" + intRoomName);

      // Build the interior data variable from DB
      var intDataStr = buildInteriorData(homeAddr, playerTribe);

      var intFrnStr = buildInteriorFrn(homeAddr, playerTribe);

      trace("[home.as] interior data=" + intDataStr + " frn=" + intFrnStr);

      var currentZone = _server.getCurrentZone();

      var existingRoom = null;

      var rooms = currentZone.getRooms();

      for (var i = 0; i < rooms.length; i++)
      {
         if (rooms[i].getName() == intRoomName)
         {
            existingRoom = rooms[i];

            break;

         }
      }

      if (existingRoom != null)
      {
         var intRVars = [
               {name: "data", val: intDataStr},
               {name: "frn", val: intFrnStr}
            ];

         _server.setRoomVariables(existingRoom, null, intRVars);

         _server.joinRoom(user, 18, true, existingRoom.getId());

      }
      else
      {
         var roomObj = {};

         roomObj.name = intRoomName;

         roomObj.maxU = 20;

         roomObj.isTemp = "true";

         var roomVars = [
               {name: "tribeID", val: playerTribe},
               {name: "tb", val: playerTribe},
               {name: "addr", val: String(homeAddr)},
               {name: "data", val: intDataStr},
               {name: "frn", val: intFrnStr}
            ];

         var newRoom = _server.createRoom(roomObj, null, true, true, roomVars);

         _server.joinRoom(user, 18, true, newRoom.getId());

      }

      // Set lihom user variable so exterior scene knows where this player came from
      var uVars = {};

      uVars.lihom = String(homeAddr);

      _server.setUserVariables(user, uVars, true);

      return;

   }

   // =====================================================================
   // EXTERIOR MODE: Create/join the exterior room for a street
   // =====================================================================
   var roomName = "homeExterior_" + streetNum + "_tb" + playerTribe;

   // Build the data room variable from DB
   var dataStr = buildExteriorData(streetNum, Number(playerTribe), user);

   trace("[home.as] exterior: roomName=" + roomName + " data=" + dataStr);

   var currentZone = _server.getCurrentZone();

   var existingRoom = null;

   var rooms = currentZone.getRooms();

   for (var i = 0; i < rooms.length; i++)
   {
      if (rooms[i].getName() == roomName)
      {
         existingRoom = rooms[i];

         break;

      }
   }

   if (existingRoom != null)
   {
      var rVars = [
            {name: "data", val: dataStr}
         ];

      _server.setRoomVariables(existingRoom, null, rVars);

      _server.joinRoom(user, 18, true, existingRoom.getId());

   }
   else
   {
      // Create a new temporary room
      var roomObj = {};

      roomObj.name = roomName;

      roomObj.maxU = 50;

      roomObj.isTemp = "true";

      var roomVars = [
            {name: "tribeID", val: playerTribe},
            {name: "tb", val: playerTribe},
            {name: "addr", val: String(streetNum)},
            {name: "data", val: dataStr}
         ];

      var newRoom = _server.createRoom(roomObj, null, true, true, roomVars);

      _server.joinRoom(user, 18, true, newRoom.getId());

   }
}


// ============================================================================
// door  -  Open/close or lock/unlock a door
// Client sends: cmd="door", params.id = global homeAddr, params.lk = 1 (lock toggle)
// ============================================================================
function cmdDoor(user, room, params)
{
   var doorAddr = Number(params.id);

   if (isNaN(doorAddr) || doorAddr < 1)
   {
      trace("[home.as] door: invalid doorAddr=" + params.id);

      return;

   }

   var isLockToggle = (params.lk != undefined && Number(params.lk) == 1);

   // --- Compute street and slot from the global address ---
   var streetNum = Math.ceil(doorAddr / 3);

   var slot = ((doorAddr - 1) % 3) + 1;

   trace("[home.as] door: doorAddr=" + doorAddr + " street=" + streetNum + " slot=" + slot + " lock=" + isLockToggle);

   var roomTribe = getRoomVar(room, "tb");

   if (roomTribe == null || roomTribe == "")
   {
      roomTribe = getAccountValue(user.getName(), "tribe_id");

   }
   if (roomTribe == null || roomTribe == "")
      roomTribe = "1";

   var sqlHome = "SELECT * FROM cc_homes WHERE street_num=" + streetNum + " AND slot=" + slot + " AND tribe_ID=" + roomTribe;

   var qrHome = dbase.executeQuery(sqlHome);

   if (qrHome == null || qrHome.size() == 0)
   {
      trace("[home.as] door: no home found at street=" + streetNum + " slot=" + slot);

      return;

   }

   var homeRow = qrHome.get (0);

   var homeOwner = Number(homeRow.getItem("user_id"));

   var doorState = Number(homeRow.getItem("door_state"));

   var homeTribe = Number(homeRow.getItem("tribe_ID"));

   // --- Ownership check
   var myDbId = getDbUserId(user);

   trace("[home.as] door: homeOwner=" + homeOwner + " myDbId=" + myDbId + " currentState=" + doorState);

   if (isLockToggle)
   {
      // Lock/unlock only the owner can do this
      if (myDbId != homeOwner)
      {
         trace("[home.as] door: lock denied, not owner");

         return;

      }

      if (doorState == 2)
      {
         // Currently locked > unlock (set to closed)
         doorState = 0;

      }
      else
      {
         // Currently open or closed lock
         doorState = 2;

      }
   }
   else
   {
      // If locked (2), nobody can open/close it, send locked error
      if (doorState == 2)
      {
         trace("[home.as] door: door is locked, can't toggle open/close");

         var lockedObj = {};

         lockedObj._cmd = "sceneRep";

         lockedObj.sub = "doorLocked";

         _server.sendResponse(lockedObj, -1, null, [user]);

         return;

      }

      if (doorState == 0)
      {
         doorState = 1;

         // Closed to open
      }
      else if (doorState == 1)
      {
         doorState = 0;

         // Open to close
      }
   }

   var sqlUpdate = "UPDATE cc_homes SET door_state='" + doorState + "' WHERE street_num=" + streetNum + " AND slot=" + slot + " AND tribe_ID=" + homeTribe;

   trace("[home.as] door: UPDATE: " + sqlUpdate);

   dbase.executeCommand(sqlUpdate);

   var dataStr = buildExteriorData(streetNum, homeTribe, user);

   var roomName = "homeExterior_" + streetNum + "_tb" + homeTribe;

   var currentZone = _server.getCurrentZone();

   var existingExt = currentZone.getRoomByName(roomName);

   if (existingExt != null)
   {
      var rVars = [ {name: "data", val: dataStr}];

      _server.setRoomVariables(existingExt, null, rVars);

      trace("[home.as] door: exterior room vars updated");

   }

   var intRoomName = "homeInterior_" + doorAddr + "_tb" + homeTribe;

   var existingInt = currentZone.getRoomByName(intRoomName);

   if (existingInt != null)
   {
      var intDataStr = buildInteriorData(doorAddr, homeTribe);

      var iVars = [ {name: "data", val: intDataStr}];

      _server.setRoomVariables(existingInt, null, iVars);

      trace("[home.as] door: interior room vars updated");

   }
}

// ============================================================================
// buildInteriorFrn  -  Build the "frn" room variable for an interior room
// Format: "instanceId,itemId,x,y,rotation,subtype|..."
// ============================================================================
function buildInteriorFrn(homeAddr, tribeId)
{
   var snFrn = Math.ceil(homeAddr / 3);

   var slFrn = ((homeAddr - 1) % 3) + 1;

   var sqlHid = "SELECT ID FROM cc_homes WHERE street_num=" + snFrn + " AND slot=" + slFrn + " AND tribe_ID=" + tribeId;

   var qrHid = dbase.executeQuery(sqlHid);

   var realHomeId = homeAddr;

   if (qrHid != null && qrHid.size() > 0)
      realHomeId = Number(qrHid.get (0).getItem("ID"));

   var sql = "SELECT * FROM cc_homes_furniture WHERE home_id=" + realHomeId;

   var qr = dbase.executeQuery(sql);

   var parts = [];

   if (qr != null)
   {
      for (var i = 0; i < qr.size(); i++)
      {
         var row = qr.get (i);

         var fId = row.getItem("id");

         var itemId = row.getItem("item_id");

         var x = row.getItem("x_pos");

         var y = row.getItem("y_pos");

         var rot = row.getItem("rotation");

         var sub = row.getItem("is_wall");

         parts.push(fId + "," + itemId + "," + x + "," + y + "," + rot + "," + sub);

      }
   }

   return parts.join("|");

}

// ============================================================================
// homeInterior  -  Enter a house (create/join interior room)
// Client sends: cmd="homeInterior", params.addr = global home address
// ============================================================================
function cmdHomeInterior(user, room, params, fromRoom)
{
   var addr = Number(params.addr);

   if (isNaN(addr) || addr < 1)
      return;

   var streetNum = Math.ceil(addr / 3);

   var slot = ((addr - 1) % 3) + 1;

   // --- Check door is open ---
   var roomTribe = getRoomVar(room, "tb");

   if (roomTribe == null || roomTribe == "")
      roomTribe = "1";

   var sqlHome = "SELECT * FROM cc_homes WHERE street_num=" + streetNum + " AND slot=" + slot + " AND tribe_ID=" + roomTribe;

   var qrHome = dbase.executeQuery(sqlHome);

   if (qrHome == null || qrHome.size() == 0)
      return;

   var homeRow = qrHome.get (0);

   var doorState = Number(homeRow.getItem("door_state"));

   var homeTribe = String(homeRow.getItem("tribe_ID"));

   if (doorState != 1)
   {
      return;

      // Door is not open
   }

   var roomName = "homeInterior_" + addr + "_tb" + homeTribe;

   var currentZone = _server.getCurrentZone();

   var existingRoom = null;

   var rooms = currentZone.getRooms();

   for (var i = 0; i < rooms.length; i++)
   {
      if (rooms[i].getName() == roomName)
      {
         existingRoom = rooms[i];

         break;

      }
   }

   if (existingRoom != null)
   {
      _server.joinRoom(user, fromRoom, true, existingRoom.getId());

   }
   else
   {
      var roomObj = {};

      roomObj.name = roomName;

      roomObj.maxU = 20;

      roomObj.isTemp = "true";

      var intDataStr = buildInteriorData(addr, homeTribe);

      var intFrnStr = buildInteriorFrn(addr, homeTribe);

      var roomVars = [
            {name: "tribeID", val: homeTribe},
            {name: "tb", val: homeTribe},
            {name: "addr", val: String(addr)},
            {name: "data", val: intDataStr},
            {name: "frn", val: intFrnStr}
         ];

      var newRoom = _server.createRoom(roomObj, null, true, true, roomVars);

      _server.joinRoom(user, fromRoom, true, newRoom.getId());

   }

   // Set the lihom user variable so exterior knows where this player came from
   var uVars = {};

   uVars.lihom = String(addr);

   _server.setUserVariables(user, uVars, true);

}

// ============================================================================
// homeExit  -  Leave interior, go back to exterior
// ============================================================================
function cmdHomeExit(user, room, params, fromRoom)
{
   var addr = Number(params.addr);

   if (isNaN(addr) || addr < 1)
      return;

   var streetNum = Math.ceil(addr / 3);

   var playerTribe = getRoomVar(room, "tribeID");

   if (playerTribe == null || playerTribe == "")
      playerTribe = getRoomVar(room, "tb");

   if (playerTribe == null || playerTribe == "")
      playerTribe = "1";

   var roomName = "homeExterior_" + streetNum + "_tb" + playerTribe;

   var currentZone = _server.getCurrentZone();

   var rooms = currentZone.getRooms();

   for (var i = 0; i < rooms.length; i++)
   {
      if (rooms[i].getName() == roomName)
      {
         _server.joinRoom(user, fromRoom, true, rooms[i].getId());

         return;

      }
   }

   // Exterior room doesn't exist anymore - recreate it
   cmdHome(user, room, {hid: addr}, fromRoom);

}

// ============================================================================
// getMail  -  Fetch all messages for the current user
// Format: "0~senderName~date~0~subject~message~isRead~mailId"
// ============================================================================
function cmdGetMail(user, room)
{
   var dbId = getDbUserId(user);

   var sql = "SELECT * FROM cc_mail WHERE receiver_id = " + dbId + " ORDER BY created DESC";

   var qr = dbase.executeQuery(sql);

   var mailList = [];

   if (qr != null)
   {
      for (var i = 0; i < qr.size(); i++)
      {
         var row = qr.get (i);

         var mId = row.getItem("id");

         var sId = row.getItem("sender_id");

         var date = row.getItem("created");

         var subject = row.getItem("subject");

         var message = row.getItem("message");

         var isRead = row.getItem("is_read");

         var sName = "Unknown";

         var sqlUser = "SELECT username FROM cc_user WHERE ID = " + sId;

         var qrUser = dbase.executeQuery(sqlUser);

         if (qrUser != null && qrUser.size() > 0)
         {
            sName = qrUser.get (0).getItem("username");

         }

         // Client expects: 0~senderName~date~0~subject~message~isRead~mailId
         var mStr = "0~" + sName + "~" + date + "~0~" + subject + "~" + message + "~" + isRead + "~" + mId;

         mailList.push(mStr);

      }
   }

   var res = {};

   res._cmd = "mail";

   res.sub = "lst";

   if (mailList.length == 0)
   {
      res.data = "";

   }
   else
   {
      res.data = mailList.join("|");

   }

   _server.sendResponse(res, -1, null, [user]);

}

// ============================================================================
// sendMail  -  Send a message to another user
// params: to (target username), msg (message text)
// ============================================================================
function cmdSendMail(user, room, params)
{
   var senderId = getDbUserId(user);

   var targetName = params.to;

   var message = params.msg;

   if (targetName == null || targetName == "" || message == null || message == "")
      return;

   var sqlUser = "SELECT ID FROM cc_user WHERE username = '" + targetName + "'";

   var qrUser = dbase.executeQuery(sqlUser);

   if (qrUser == null || qrUser.size() == 0)
   {
      var res = {};

      res._cmd = "sendfail";

      _server.sendResponse(res, -1, null, [user]);

      return;

   }

   var receiverId = qrUser.get (0).getItem("ID");

   var sqlIns = "INSERT INTO cc_mail (sender_id, receiver_id, subject, message, is_read) " +
      "VALUES (" + senderId + ", " + receiverId + ", 'Home Mail', '" + _server.escapeQuotes(message) + "', 0)";

   var success = dbase.executeCommand(sqlIns);

   if (success)
   {
      var money = getAccountValue(user.getName(), "money");

      if (money == null || money == "")
         money = "0,0";

      var purseRes = {};

      purseRes._cmd = "purse";

      purseRes.cr = money;

      _server.sendResponse(purseRes, -1, null, [user]);

      var succRes = {};

      succRes._cmd = "sendSucc";

      succRes.to = targetName;

      succRes.cr = money;

      _server.sendResponse(succRes, -1, null, [user]);

      var receiverHomeAddr = getAccountValue(targetName, "homeAddr");

      if (receiverHomeAddr != null && receiverHomeAddr != "" && receiverHomeAddr != "-1")
      {
         var targetTribe = getAccountValue(targetName, "tribe_id");

         if (targetTribe == "")
            targetTribe = "1";

         var intRoomName = "homeInterior_" + receiverHomeAddr + "_tb" + targetTribe;

         var currentZone = _server.getCurrentZone();

         var existingRoom = currentZone.getRoomByName(intRoomName);

         if (existingRoom != null)
         {
            var intDataStr = buildInteriorData(Number(receiverHomeAddr), targetTribe);

            var rVars = [ {name: "data", val: intDataStr}];

            _server.setRoomVariables(existingRoom, null, rVars);

         }
      }
   }
   else
   {
      var failRes = {};

      failRes._cmd = "sendfail";

      _server.sendResponse(failRes, -1, null, [user]);

   }
}

// ============================================================================
// readMail - Mark a message as read
// params: id (mail id)
// ============================================================================
function cmdReadMail(user, room, params)
{
   var dbId = getDbUserId(user);

   var mailId = params.id;

   if (mailId == null)
      return;

   var sql = "UPDATE cc_mail SET is_read = 1 WHERE id = " + mailId + " AND receiver_id = " + dbId;

   dbase.executeCommand(sql);

   var homeAddr = getAccountValue(user.getName(), "homeAddr");

   if (homeAddr != null && homeAddr != "" && homeAddr != "-1")
   {
      var tribeId = getAccountValue(user.getName(), "tribe_id");

      if (tribeId == "")
         tribeId = "1";

      var intRoomName = "homeInterior_" + homeAddr + "_tb" + tribeId;

      var currentZone = _server.getCurrentZone();

      var existingRoom = currentZone.getRoomByName(intRoomName);

      if (existingRoom != null)
      {
         var intDataStr = buildInteriorData(Number(homeAddr), tribeId);

         var rVars = [ {name: "data", val: intDataStr}];

         _server.setRoomVariables(existingRoom, null, rVars);

      }
   }
}

// ============================================================================
// buildExteriorData  -  Build the "data" room variable for a given street
// 
// Returns: "doorState,userId,username|doorState,userId,username|doorState,userId,username"
// For empty slots: "0,0,<For Rent text>"
// ============================================================================
function buildExteriorData(streetNum, tribeID, user)
{
   var sqlHomes = "SELECT h.*, u.username FROM cc_homes h LEFT JOIN cc_user u ON h.user_id = u.ID WHERE h.street_num=" + streetNum + " AND h.tribe_ID=" + tribeID + " ORDER BY h.slot ASC";

   trace("[home.as] buildExteriorData SQL: " + sqlHomes);

   var qrHomes = dbase.executeQuery(sqlHomes);

   // Build a map: slot - {doorState, userId, username}
   var slotMap = {};

   if (qrHomes != null)
   {
      for (var i = 0; i < qrHomes.size(); i++)
      {
         var row = qrHomes.get (i);

         var sl = String(row.getItem("slot"));

         var uname = row.getItem("username");

         if (uname == null || uname == "null" || uname == "")
            uname = "0";

         slotMap[sl] = {
               doorState: String(row.getItem("door_state")),
               userId: String(row.getItem("user_id")),
               username: uname
            };

         trace("[home.as] buildExteriorData: slot " + sl + " = " + slotMap[sl].doorState + "," + slotMap[sl].userId + "," + slotMap[sl].username);

      }
   }

   // Build the pipe-separated data string for slots 1, 2, 3
   var parts = [];

   for (var s = 1; s <= 3; s++)
   {
      var key = String(s);

      if (slotMap[key])
      {
         parts.push(slotMap[key].doorState + "," + slotMap[key].userId + "," + slotMap[key].username);

      }
      else
      {
         parts.push("0,0," + getForRentText(user));

      }
   }

   return parts.join("|");

}

// ============================================================================
// buildInteriorData  -  Build the "data" room variable for an interior room
// 
// The interior client expects: "doorState,userId,username,mailCount"
// - doorState: 0=closed, 1=open, 2=locked
// - userId: owner's cc_user.ID
// - username: owner's username
// - mailCount: number of unread mail
// ============================================================================
function buildInteriorData(homeAddr, tribeId)
{
   var streetNum = Math.ceil(homeAddr / 3);

   var slot = ((homeAddr - 1) % 3) + 1;

   var sql = "SELECT h.*, u.username FROM cc_homes h LEFT JOIN cc_user u ON h.user_id = u.ID WHERE h.street_num=" + streetNum + " AND h.slot=" + slot + " AND h.tribe_ID=" + tribeId;

   trace("[home.as] buildInteriorData SQL: " + sql);

   var qr = dbase.executeQuery(sql);

   if (qr == null || qr.size() == 0)
   {
      return "0,0,0,0";

   }

   var row = qr.get (0);

   var dState = String(row.getItem("door_state"));

   var uid = String(row.getItem("user_id"));

   var uname = row.getItem("username");

   if (uname == null || uname == "null" || uname == "")
      uname = "0";

   var mailCount = "0";

   var sqlMail = "SELECT COUNT(*) as unread FROM cc_mail WHERE receiver_id = " + uid + " AND is_read = 0";

   var qrMail = dbase.executeQuery(sqlMail);

   if (qrMail != null && qrMail.size() > 0)
   {
      mailCount = String(qrMail.get (0).getItem("unread"));

   }

   var result = dState + "," + uid + "," + uname + "," + mailCount;

   trace("[home.as] buildInteriorData: " + result);

   return result;

}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function getForRentText(user)
{
   var lang = "0";

   if (user != null)
   {
      var lan = user.properties.get("lang");

      if (lan != null) lang = String(lan);

   }

   if (lang == "1") return "للايجار";

   return "For Rent";

}

function getPlayerVar(user, varName)
{
   var varObj = user.getVariable(varName);

   return varObj.getValue();

}

function getRoomVar(room, varName)
{
   var varObj = room.getVariable(varName);

   if (varObj == null)
      return null;

   return varObj.getValue();

}

function getAccountValue(userNorID, value)
{
   if (Number(userNorID))
   {
      var sql = "SELECT * FROM cc_user WHERE id=" + userNorID;

   }
   else
   {
      var sql = "SELECT * FROM cc_user WHERE username='" + userNorID + "'";

   }
   var queryRes = dbase.executeQuery(sql);

   if (queryRes == null || queryRes.size() == 0)
      return "";

   var row = queryRes.get (0);

   var res = row.getItem(value);

   return (res == null) ? "" : String(res);

}

function setAccountValue(userNorID, colName, value)
{
   if (Number(userNorID))
   {
      var sql = "UPDATE cc_user SET " + colName + " = '" + value + "' WHERE id = " + userNorID;

   }
   else
   {
      var sql = "UPDATE cc_user SET " + colName + " = '" + value + "' WHERE username = '" + userNorID + "'";

   }
   var success = dbase.executeCommand(sql);

   return success;

}

// ============================================================================
// cmdDropFurniture (drp)
// Client sends: fid=itemId, co="x,y,rotation"
// ============================================================================
function cmdDropFurniture(user, room, params)
{
   var fid = Number(params.fid);

   var coArr = String(params.co).split(",");

   if (coArr.length < 3)
   {
      trace("[drp] coArr < 3: " + params.co);
      return;

   }

   var x = Number(coArr[0]);

   var y = Number(coArr[1]);

   var rot = Number(coArr[2]);

   if (isNaN(rot))
      rot = 1;

   var homeAddr = getRoomVar(room, "addr");

   if (homeAddr == null)
   {
      trace("[drp] homeAddr is null!");
      return;

   }

   // Determine if allowed (home owner only)
   var myDbId = getDbUserId(user);

   var streetNum = Math.ceil(homeAddr / 3);

   var slot = ((homeAddr - 1) % 3) + 1;

   var roomTribe = getRoomVar(room, "tb");

   if (roomTribe == null)
      roomTribe = "1";

   var sqlHome = "SELECT user_id, ID FROM cc_homes WHERE street_num=" + streetNum + " AND slot=" + slot + " AND tribe_ID=" + roomTribe;

   var qrHome = dbase.executeQuery(sqlHome);

   if (qrHome == null || qrHome.size() == 0)
   {
      trace("[drp] qrHome is null/empty!");
      return;

   }
   var homeOwner = Number(qrHome.get (0).getItem("user_id"));

   var realDrpHomeId = Number(qrHome.get (0).getItem("ID"));

   var roomTribeDrp = roomTribe;

   if (myDbId != homeOwner)
   {
      trace("[drp] Not home owner! myDbId: " + myDbId + ", homeOwner: " + homeOwner);
      return;

   }

   var sqlUser = "SELECT inventory FROM cc_user WHERE username='" + _server.escapeQuotes(user.getName()) + "'";

   var qrUser = dbase.executeQuery(sqlUser);

   var hasItem = false;

   if (qrUser != null && qrUser.size() > 0)
   {
      var invStr = String(qrUser.get (0).getItem("inventory"));

      if (invStr != null && invStr != "")
      {
         var parts = invStr.split("|");

         var newParts = [];

         for (var i = 0; i < parts.length; i++)
         {
            var subParts = parts[i].split("~");

            if (!hasItem && subParts[0] == String(fid))
            {
               hasItem = true;

            }
            else
            {
               newParts.push(parts[i]);

            }
         }
         if (hasItem)
         {
            var newInv = newParts.join("|");

            var sqlUpd = "UPDATE cc_user SET inventory='" + _server.escapeQuotes(newInv) + "' WHERE username='" + _server.escapeQuotes(user.getName()) + "'";

            dbase.executeCommand(sqlUpd);

         }
      }
   }
   if (!hasItem)
   {
      trace("[drp] User does not have item " + fid + " in inventory!");
      return;

   }

   // Fetch subtype (kind) from cc_invlist
   var subtype = 0;

   var sqlItem = "SELECT kind FROM cc_invlist WHERE objID=" + fid;

   var qrItem = dbase.executeQuery(sqlItem);

   if (qrItem != null && qrItem.size() > 0)
   {
      var kStr = qrItem.get (0).getItem("kind");

      if (kStr != null && kStr != "")
         subtype = Number(kStr);

   }

   var sqlInsert = "INSERT INTO cc_homes_furniture (home_id, item_id, x_pos, y_pos, rotation, is_wall) VALUES (" + realDrpHomeId + ", " + fid + ", " + x + ", " + y + ", " + rot + ", " + subtype + ")";

   dbase.executeCommand(sqlInsert);

   var sqlId = "SELECT MAX(id) as mx FROM cc_homes_furniture WHERE home_id=" + realDrpHomeId + " AND item_id=" + fid;

   var qrId = dbase.executeQuery(sqlId);

   var instId = -1;

   if (qrId != null && qrId.size() > 0)
   {
      instId = Number(qrId.get (0).getItem("mx"));

   }

   var frnItem = instId + "," + fid + "," + x + "," + y + "," + rot + "," + subtype;

   var frnStr = buildInteriorFrn(homeAddr, roomTribe);

   var rVars = [ {name: "frn", val: frnStr}];

   _server.setRoomVariables(room, null, rVars);

   var resObj = {};

   resObj._cmd = "pfrn";

   resObj.frn = frnItem;

   resObj.id = String(fid);

   _server.sendResponse(resObj, -1, null, room.getAllUsers());

}

// ============================================================================
// cmdEditFurniture (edt)
// Client sends: data=String([instId, itemId, x, y, rot, subtype])
// ============================================================================
function cmdEditFurniture(user, room, params)
{
   var dataArr = String(params.data).split(",");

   if (dataArr.length < 5)
      return;

   var instId = Number(dataArr[0]);

   var x = Number(dataArr[2]);

   var y = Number(dataArr[3]);

   var rot = Number(dataArr[4]);

   var sqlUpdate = "UPDATE cc_homes_furniture SET x_pos=" + x + ", y_pos=" + y + ", rotation=" + rot + " WHERE id=" + instId;

   dbase.executeCommand(sqlUpdate);

   var homeAddr = getRoomVar(room, "addr");

   var roomTribeEdt = getRoomVar(room, "tribeID");

   if (roomTribeEdt == null || roomTribeEdt == "")
      roomTribeEdt = getRoomVar(room, "tb");

   if (roomTribeEdt == null || roomTribeEdt == "")
      roomTribeEdt = "1";

   if (homeAddr != null)
   {
      var frnStr = buildInteriorFrn(homeAddr, roomTribeEdt);

      var rVars = [ {name: "frn", val: frnStr}];

      _server.setRoomVariables(room, null, rVars);

   }

   var resObj = {};

   resObj._cmd = "afrn";

   resObj.frn = String(params.data);

   _server.sendResponse(resObj, -1, null, room.getAllUsers());

}

// ============================================================================
// cmdGetFurniture (get)
// Client sends: fid=instId
// ============================================================================
function cmdGetFurniture(user, room, params)
{
   var instId = Number(params.fid);

   // Fetch before deleting to get itemId
   var sqlId = "SELECT item_id FROM cc_homes_furniture WHERE id=" + instId;

   var qrId = dbase.executeQuery(sqlId);

   if (qrId == null || qrId.size() == 0)
      return;

   var itemId = Number(qrId.get (0).getItem("item_id"));

   var sqlDel = "DELETE FROM cc_homes_furniture WHERE id=" + instId;

   dbase.executeCommand(sqlDel);

   var homeAddr = getRoomVar(room, "addr");

   var roomTribeGet = getRoomVar(room, "tribeID");

   if (roomTribeGet == null || roomTribeGet == "")
      roomTribeGet = getRoomVar(room, "tb");

   if (roomTribeGet == null || roomTribeGet == "")
      roomTribeGet = "1";

   if (homeAddr != null)
   {
      var frnStr = buildInteriorFrn(homeAddr, roomTribeGet);

      var rVars = [ {name: "frn", val: frnStr}];

      _server.setRoomVariables(room, null, rVars);

   }

   var sqlItem = "SELECT * FROM cc_invlist WHERE objID=" + itemId;

   var qrItem = dbase.executeQuery(sqlItem);

   if (qrItem != null && qrItem.size() > 0)
   {
      var row = qrItem.get (0);

      var objectID = row.getItem("objID");

      var SwfID = row.getItem("swfID");

      var objectName = row.getItem("name");

      var description = row.getItem("description");

      var ObjectType = row.getItem("type");

      var Exchange = row.getItem("exchange");

      var kind = row.getItem("kind");

      var lvl = row.getItem("lvl");

      var invStr = objectID + "~" + objectID + "~" + SwfID + "~" + objectName + "~" + description + "~" + ObjectType + "~" + Exchange + "~" + kind + "~" + lvl;

      var sqlUser = "SELECT inventory FROM cc_user WHERE username='" + _server.escapeQuotes(user.getName()) + "'";

      var qrUser = dbase.executeQuery(sqlUser);

      if (qrUser != null && qrUser.size() > 0)
      {
         var fullInv = String(qrUser.get (0).getItem("inventory"));

         var newFullInv = "";

         if (fullInv == null || fullInv == "")
         {
            newFullInv = invStr;

         }
         else
         {
            newFullInv = fullInv + "|" + invStr;

         }
         var sqlUpd = "UPDATE cc_user SET inventory='" + _server.escapeQuotes(newFullInv) + "' WHERE username='" + _server.escapeQuotes(user.getName()) + "'";

         dbase.executeCommand(sqlUpd);

      }

      var resObjInv = {};

      resObjInv._cmd = "ginv";

      resObjInv.adinv = invStr;

      _server.sendResponse(resObjInv, -1, null, [user]);

   }

   var resObjMenu = {};

   resObjMenu._cmd = "rfrn";

   resObjMenu.id = String(instId);

   _server.sendResponse(resObjMenu, -1, null, room.getAllUsers());

}