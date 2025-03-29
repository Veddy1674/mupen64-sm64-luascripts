-- Triangle.lua
local property = require("misc.Utils")

local triangle = {}
triangle.__index = triangle

-- mario_base is an argument because Mario.lua requires Triangle.lua and Triangle.lua requires Mario.lua (c stack overflow)
function triangle.new(triangletype, mario) -- string: "floor", "wall", "ceiling"
    local triangle = setmetatable({}, triangle)
	
	local offset =
		triangletype == "floor" and 0x68 or
		triangletype == "wall" and 0x60 or
		triangletype == "ceiling" and 0x64 or 0x0
	
	triangle.base = function()--property.new(mario.base, offset, "uint") --function()
		return memory.access(mario.base + offset, UINT)
	end
	
	triangle.height = nil
	if triangletype == "floor" then
		triangle.height = property.new(triangle.base(), 0x70, "float")
	elseif triangletype == "ceiling" then
		triangle.height = property.new(triangle.base(), 0x6C, "float")
	end
	
	triangle.distMario = nil
	if triangletype == "floor" or triangletype == "ceiling" then
		triangle.distMario = function()
			return math.abs(mario.pos.y - triangle.height())
		end
	end
	
    return triangle
end

return triangle