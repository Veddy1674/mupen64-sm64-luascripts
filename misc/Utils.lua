-- Property.lua - Required in almost every script (undirectly)

require("lua.misc.Emu")
require("lua.misc.Memory")
require("lua.misc.Joypad")
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