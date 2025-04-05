-- Property.lua - Required in almost every script (undirectly)

require("lua.misc.Emu")
require("lua.misc.Memory")
require("lua.misc.Joypad")
require("lua.math.Vector2")
require("lua.math.Vector3")
require("lua.math.Speed4")
require("lua.math.Speed9")
require("lua.math.Hitbox")
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
table.random = function(tbl)
	local count = 0
    for k in pairs(tbl) do
        if type(k) ~= "number" then
            -- non-indexed table (uses pairs)
			local keys = {}
			for k,_ in pairs(tbl) do
				table.insert(keys, k)
			end
			return keys[emu.rand(1, #keys)]
        end
        count = count + 1
    end
	-- indexed table (uses ipairs)
	return tbl[emu.rand(1, #tbl)]
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

---@param n number
hex = function(n)
    return string.format("0x%X", n)
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