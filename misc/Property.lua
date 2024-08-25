-- Property.lua - Required in almost every script (undirectly)

baseprint = print
function print(obj)
    local mt = getmetatable(obj)
    if mt and mt.__tostring then
        baseprint(mt.__tostring(obj))
    else
        baseprint(obj)
    end
end

local module = {}
module.__index = module

local um = require("math.UtilsMath")

-- property.new automatically handles the getters/setters functions

-- e.g:
--getter: print(mario.pos.x)
--setter: mario.pos.x = mario.pos.x + 20.0

-- e.g: marioutils.memory_access("write", mario.base, 0x14, graphics.door, "uint")
function memory.access(address, vartype, value)
    if (vartype == "float") then
        if value then
            memory.writefloat(address, value)
        end
		return memory.readfloat(address)
    elseif (vartype == "uint") then
        if value then
            memory.writedword(address, value)
        end
		return memory.readdword(address)
    elseif (vartype == "int") then
        if value then
            memory.writedword(address, value)
        end
		return memory.readdwordsigned(address)
    elseif (vartype == "byte") then
        if value then
            memory.writebyte(address, value)
        end
		return memory.readbyte(address)
    end
	-- type invalid
	print("Invalid memory type \"" .. vartype .. "\". " .. "(" .. (value and "write" or "read") .. ")")
	_G.stop()
	return nil
end

local defaultPrecision = 3
local _TAB = "    " -- \t looks bad, so i use a custom tab size

function module.new(base, offsets, _type, precision) -- precision is used for floats
    precision = precision or defaultPrecision

    -- first _type check, does nothing but if the _type is invalid then _G.stop() is called
    memory.access(base, _type)

    local mt
    if type(offsets) == "number" then
        mt = {
            __index = function(t, key)
                return memory.access(base + offsets, _type)
            end,
            __newindex = function(t, key, value)
				local current_value = memory.access(base + offsets, _type)
				local new_value = value
				if type(value) == "number" then
					if _type == "float" then
						new_value = um.round(value, precision) -- use value directly for floats
					else
						new_value = current_value + value
					end
				end
				memory.access(base + offsets, _type, new_value)
			end,
        }
    else
        mt = {
            __index = function(_, key)
                return memory.access(base + offsets[key], _type)
            end,
            __newindex = function(_, key, value)
				local current_value = memory.access(base + offsets[key], _type)
				local new_value = value
				if type(value) == "number" then
					if _type == "float" then
						new_value = um.round(value, precision) -- use value directly for floats
					else
						new_value = current_value + value
					end
				end
				memory.access(base + offsets[key], _type, new_value)
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
                local str = (_type == "float") and " (" .. precision .. " decimals)" or ""
                return "} - " .. _type .. str
            end,
        }
    end

    return setmetatable({}, mt)
end

return module