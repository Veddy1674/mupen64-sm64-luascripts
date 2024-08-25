-- Distance.lua
local mario = require("mario.Mario")

local module = {}

function module.marioTo(object)
	if (object.pos == nil) then
		error("Invalid object")
		return
	end
	return module.objToObj(mario, object)
end

function module.objToObj(o1, o2)
    local p1 = o1.pos
    local p2 = o2.pos

    local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    local dz = p1.z - p2.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function module.axisEqZero(o1, o2, axis) -- used to detect if mario is on top of another obj mostly, as mario point position is exactly on mario's feet
	return math.abs(o1.pos[axis] - o2.pos[axis]) == 0
	-- im too lazy to put checks like "if axis isnt x or y or z then return end"
end

return module