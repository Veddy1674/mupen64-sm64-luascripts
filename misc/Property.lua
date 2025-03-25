-- Property.lua - Required in almost every script (undirectly)

require("lua.misc.Memory")
require("lua.misc.Joypad")
require("lua.math.Vector3")
local um = require("lua.math.UtilsMath")

local defaultPrecision = 3
local _TAB = "    " -- \t looks bad, so i use a custom tab size

local property = {}

function property.new(base, offsets, _type, precision) -- precision is used for floats
    precision = precision or defaultPrecision

    -- first _type check, does nothing but if the _type is invalid then _G.stop() is called
    memory.access(base, _type)

    local mt = type(offsets) == "number" and
			{
				__call = function(_, value)
					if value then
						memory.access(base + offsets, _type, value)
					else
						return memory.access(base + offsets, _type)
					end
				end,
				__tostring = function(_)
					local value = memory.access(base + offsets, _type)
					return (_type == types.FLOAT) and tostring(um.round(value, precision)) or tostring(value)
				end
			}
		or
			{
				__index = function(_, key)
					return memory.access(base + offsets[key], _type)
				end,
				__newindex = function(_, key, value)
					memory.access(base + offsets[key], _type, value)
				end,
				__tostring = function(_)
					local result = {}
					for key, offset in pairs(offsets) do
						result[key] = um.round(memory.access(base + offset, _type), precision)
					end
					print("{")
					for key, value in pairs(result) do
						local str = (key == next(offsets, next(offsets, nil))) and "" or ", "
						print(_TAB .. key .. " = " .. value .. str)
					end
					local str = (_type == types.FLOAT) and " (" .. precision .. " decimals)" or ""
					return "} - " .. _type .. str
				end,
			}

    return setmetatable({}, mt)
end

function property.savebyte(address, offset, mask, value)
    local p = address + offset
    if value ~= nil then
        memory.writebyte(p, value and mask or 0x00)
    end
    return (memory.readbyte(p) & mask) == mask
end

return property