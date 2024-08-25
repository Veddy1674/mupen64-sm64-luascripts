-- Triangle.lua
local property = require("misc.Property")

local module = {}
module.__index = module

-- mario_base is an argument because Mario.lua requires Triangle.lua and Triangle.lua requires Mario.lua (c stack overflow)
function module.new(triangletype, mario) -- string: "floor", "wall", "ceiling"
    local triangle = setmetatable({}, module)
	
	local offset = memory.access(
		triangletype == "floor" and 0x68 or
		triangletype == "wall" and 0x60 or
		triangletype == "ceiling" and 0x64,
	"uint")
	
	triangle.base = mario.base + offset
	triangle.height = nil
	if triangletype == "floor" then
		triangle.height = property.new(triangle.base, 0x70, "float", 1)
	elseif triangletype == "ceiling" then
		triangle.height = property.new(triangle.base, 0x6C, "float", 1)
	end
	
	triangle.distMario = nil
	if triangletype == "floor" or triangletype == "ceiling" then
		triangle.distMario = function()
			return math.abs(mario.pos.y - triangle.height.value)
		end
	end
	
    return triangle
end

return module