-- Utils.lua - Required in almost every script (undirectly)

require("lua.misc.Emu")
require("lua.misc.Memory")
require("lua.misc.Avi")
require("lua.misc.Joypad")
require("lua.math.Vector2")
require("lua.math.Vector3")
require("lua.math.Vertices")
require("lua.math.Speed4")
require("lua.math.Speed9")
require("lua.math.Hitbox")
require("lua.math.Raycast")
um = require("lua.math.UtilsMath")

-- general

---@param tbl table
---@param condition fun(o:any):boolean
table.compare = function(tbl, condition)
	for _, v in ipairs(tbl) do
		if condition(v) then return v end
	end
	return nil
end

---@param tbl table
---@param condition fun(o:any):boolean
table.any = function(tbl, condition)
	return table.compare(tbl, condition) ~= nil
end

---@param tbl table<any, any>
---@return any[]
function table.keys(tbl)
    -- if it's already indexed just return tbl, else return indexed table
    -- (might not 100% work)
    if #tbl > 0 then
        return tbl
    else
        local values = {}
        for _, v in pairs(tbl) do
            table.insert(values, v)
        end
        return values
    end
end

---@param tbl table<any, any>
---@return any
table.random = function(tbl)
	local keys = table.keys(tbl)
    return keys[math.random(1, #keys)]
end

table.randomKey = function(tbl) -- for non-indexed only
    local randomIndex = math.random(1, #table.keys(tbl))

    local i = 1
    for key, _ in pairs(tbl) do
        if i == randomIndex then return key end
        i = i + 1
    end
end

table.randomValue = function(tbl) -- for non-indexed only
    local randomIndex = math.random(1, #table.keys(tbl))

    local i = 1
    for _, val in pairs(tbl) do
        if i == randomIndex then return val end
        i = i + 1
    end
end

---@param tbl table<any, any>
---@param tbl2 table<any, any>
table.insertAll = function(tbl, tbl2)
    for k, v in pairs(tbl2) do
        tbl[k] = v
    end
end

-- Returns a shallow copy of arg1
---@param tbl table<any, any>
table.copy = function(tbl)
    local t = {}
    for k, v in pairs(tbl) do
        t[k] = v
    end
    return t
end

-- Compares two tables recursively
---@param a table<any, any>
---@param b table<any, any>
table.equals = function(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" or type(b) ~= "table" then return false end

    for k, v in pairs(a) do
        if not table.equals(v, b[k]) then return false end
    end

    for k, v in pairs(b) do
        if not table.equals(v, a[k]) then return false end
    end

    return true
end

-- Faster version of table.insert (unsafe)
---@param tbl table<any, any>
---@param val any
table.fastinsert = function(tbl, val)
    tbl[#tbl + 1] = val
end

-- Returns the index of the first occurrence of value in tbl, or -1 if not found
---@param tbl table<any, any>
---@param value any
---@return number
table.find = function(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then return i end
    end
    return -1
end

---@param n number
hex = function(n)
    return string.format("0x%X", n)
end

---@param a number
---@param b number
function math.randomforcefloat(a, b)
    return a + (b - a) * math.random()
end

---@param x? number
---@return number
math.hyperbolicTangent = function(x) -- math.tanh is deprecated
    if x == nil then return 0 end
    if x == 0 then return 0 end
    local e = math.exp(2 * x)
    return (e - 1) / (e + 1)
end

---@param x number
---@param y number
---@return number
math.power = function(x, y)
    local result = 1
    for i = 1, y do
        result = result * x
    end
    return result
end

string.split = function(str, sep)
    local result = {}
    for part in str:gmatch("([^"..sep.."]+)") do
        table.insert(result, part)
    end
    return result
end

string.specialFormatNumber = function(num) -- custom format that adds a dot every 3 digits from the right
    local reversed = string.reverse(num)
    -- add a dot every 3 digits if there is a character after it
    local formatted = ""
    for i = 1, #reversed do
        formatted = formatted .. reversed:sub(i, i)
        if i % 3 == 0 and i ~= #reversed then
            formatted = formatted .. "."
        end
    end
    return string.reverse(formatted)
end

printf = function(fmt, ...)
    local args = {...}

    for i, arg in ipairs(args) do
        if arg == math.huge or  arg == -math.huge then
            args[i] = -1 -- when a variable is formatted as %d or %f but has value math.huge, it becomes a string
        end
    end

    local formatted = string.format(fmt, table.unpack(args))
    
    if formatted:find("\n") then
        for _, line in ipairs(formatted:split("\n")) do
            print(line)
            print()
        end
    else
        print(formatted)
    end
end

-- property:

local property = {}

function property.savebyte(address, offset, mask, value)
    local p = address + offset
    if value ~= nil then
		---@diagnostic disable-next-line: undefined-field
        _memory.writebyte(p, value and mask or 0x00)
    end
	---@diagnostic disable-next-line: undefined-field
    return (_memory.readbyte(p) & mask) == mask
end

return property