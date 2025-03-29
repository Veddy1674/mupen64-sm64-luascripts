-- Distance.lua

require("misc.Utils")

local module = {}

---@return number
function module.objToObj(o1, o2)
	
	if (not o1 or not o1.pos) then
		print("Object in argument 1 is invalid")
		---@type number
		return nil
	elseif (not o2 or not o2.pos) then
		print("Object in argument 2 is invalid")
		---@type number
		return nil
	end
	
    local p1 = o1.pos
    local p2 = o2.pos

    local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    local dz = p1.z - p2.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@return Vector3
function module.worldDistance(o1, o2)
	if (not o1 or not o1.pos) then
		print("Object in argument 1 is invalid")
		---@type Vector3
		return nil
	elseif (not o2 or not o2.pos) then
		print("Object in argument 2 is invalid")
		---@type Vector3
		return nil
	end

	local dx = o1.pos.x - o2.pos.x
    local dy = o1.pos.y - o2.pos.y
    local dz = o1.pos.z - o2.pos.z
	return Vector3.new(dx, dy, dz)
end

function module.axisEqZero(o1, o2, axis) -- used to detect if mario is on top of another obj mostly, as mario point position is exactly on mario's feet
	return math.abs(o1.pos[axis] - o2.pos[axis]) == 0
	-- todo: "if axis isnt x or y or z then return end..."
end

return module