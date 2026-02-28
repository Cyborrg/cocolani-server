// ==========================================================
// jungle_temple.as
// Handles jungle temple scene commands: door, gem
//==========================================================


function init()   {}
function destroy() {}

function handleRequest(cmd, params, user, fromRoom)
{
    trace("jungle_temple cmd: " + cmd)

    var zone = _server.getCurrentZone()
    var room = zone.getRoom(fromRoom)

    if (cmd == "door")
    {
        var rVars = []
        rVars.push({ name: "door", val: 1, priv: true, persistent: false })
        _server.setRoomVariables(room, user, rVars)
    }
    else if (cmd == "gem")
    {
        if (!isValidUInt(params.id))
        {
            // TODO_AC: ban user

            trace("BLOCKED: invalid gem id from " + user.getName())
            return
        }

        var itemObjId = String(Number(params.id))
        var username  = user.getName()

        var pzl       = dbGetUserField(username, "pzl")
        var inventory = dbGetUserField(username, "inventory")

        if (pzl == null || inventory == null)
        {
            trace("gem: could not read user data for " + username)
            return
        }

        var result = removeFromInventory(String(inventory), itemObjId)
        if (!result.removed)
        {
            // TODO_AC: ban user
            trace("BLOCKED: " + username + " does not own gem " + itemObjId)
            return
        }

        var resp1 = {}
        resp1._cmd   = "sceneRep"
        resp1.sub    = "puz"
        resp1.pzlupd = "0"
        _server.sendResponse(resp1, -1, null, [user])

        var resp2 = {}
        resp2._cmd = "dinv"
        resp2.id   = itemObjId
        _server.sendResponse(resp2, -1, null, [user])

        var newPzl = (String(pzl) == "") ? "0" : (String(pzl) + ",0")
        dbSaveUserField(username, "pzl", newPzl)
        dbSaveUserField(username, "inventory", result.inv)
    }
}

function handleInternalEvent(evt) {}




// DB Utility Layer

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

function isValidUInt(val)
{
    if (val == null || val == undefined || val == "") return false;
    var n = Number(val);
    return !isNaN(n) && n >= 0 && n == Math.floor(n);
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



// ===== Inventory Utility =====

// Removes the first inventory entry matching targetObjId.
// Returns { inv: <new string>, removed: <bool> }
function removeFromInventory(inv, targetObjId)
{
    var invArray = inv.split("|")
    var newArray = []
    var removed  = false
    for (var i = 0; i < invArray.length; i++)
    {
        var parts = invArray[i].split("~")
        if (!removed && parts.length > 0 && parts[0] == String(targetObjId))
        {
            removed = true
        }
        else
        {
            newArray.push(invArray[i])
        }
    }
    return { inv: newArray.join("|"), removed: removed }
}

