-- Camera.lua

require("lua.misc.Utils")

local camera = {}
camera.base = 0x8033C520

---@param v? Vector3
---@return Vector3
camera.pos = function(v)
	local x = memory.access(camera.base + 0x184, FLOAT, v and v.x or nil)
	local y = memory.access(camera.base + 0x188, FLOAT, v and v.y or nil)
	local z = memory.access(camera.base + 0x18C, FLOAT, v and v.z or nil)
	return Vector3.new(x, y, z)
end
---@param v? Vector3
---@return Vector3
camera.goal = function(v)
	local x = memory.access(camera.base + 0x19C, FLOAT, v and v.x or nil)
	local y = memory.access(camera.base + 0x1A0, FLOAT, v and v.y or nil) 
	local z = memory.access(camera.base + 0x1A4, FLOAT, v and v.z or nil)
	return Vector3.new(x, y, z)
end
---@param v? Vector3
---@return Vector3
camera.focus = function(v)
	local x = memory.access(camera.base + 0x178, FLOAT, v and v.x or nil)
	local y = memory.access(camera.base + 0x17C, FLOAT, v and v.y or nil) 
	local z = memory.access(camera.base + 0x180, FLOAT, v and v.z or nil)
	return Vector3.new(x, y, z)
end
camera.yaw = function(yaw)
	return memory.access(camera.base + 0x1C6, USHORT, yaw)
end
camera.yawRad = function(yaw)
	return (camera.yaw() / 65535) * (2 * math.pi)
end
camera.pitch = function(pitch)
	return memory.access(camera.base + 0x1C4, USHORT, pitch)
end
camera.pitchRad = function(yaw)
	return (camera.pitch() / 65535) * (2 * math.pi)
end

return camera