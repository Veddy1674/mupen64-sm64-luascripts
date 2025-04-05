-- Mario.lua

-- local triangle = require("mario.Triangle")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")

local mario = {}
mario.base = 0x8033B170

---@return Object|nil
mario.getObj = function()
	---@param o Object
	return table.compare(om.getObjects(), function(o) return o.isA("Mario") end)
end

---@param v? Vector3
---@return Vector3
mario.pos = function(v)
	local x = memory.access(mario.base + 0x3C, FLOAT, v and v.x or nil)
	local y = memory.access(mario.base + 0x40, FLOAT, v and v.y or nil)
	local z = memory.access(mario.base + 0x44, FLOAT, v and v.z or nil)
	return Vector3.new(x, y, z)
end

---@param v? Speed9
---@return Speed9
mario.speed = function(v)
	local x = memory.access(mario.base + 0x48, FLOAT, v and v.x or nil)
	local y = memory.access(mario.base + 0x4C, FLOAT, v and v.y or nil)
	local z = memory.access(mario.base + 0x50, FLOAT, v and v.z or nil)
	local h = memory.access(mario.base + 0x54, FLOAT, v and v.h or nil)
	local defacto = 0
	local sideways = 0
	local xSliding = memory.access(mario.base + 0x58, FLOAT, v and v.xSliding or nil)
	local zSliding = memory.access(mario.base + 0x5C, FLOAT, v and v.zSliding or nil)
	local hSliding = 0
	return Speed9.new(x, y, z, h, defacto, sideways, xSliding, zSliding, hSliding)
end

---@param marioObj Object -- the object representing Mario (to save ram instead of getting obj everytime)
---@param goalObj Object -- the target object to follow
---@param maxSpeed boolean -- if true, applies maximum input strength, if false only the normalized direction
---@return Inputs -- returns the input values needed to move towards the goal
mario.getFollowInputs = function(marioObj, goalObj, maxSpeed)
    local yaw = camera.yawRad()
    local distance = marioObj.distanceXZFrom(goalObj)
    local absDirection = distance.normalize()
    
    -- convert absolute direction to camera-relative direction
	local relX, relZ =
		absDirection.x * math.cos(yaw) - absDirection.z * math.sin(yaw),
		absDirection.x * math.sin(yaw) + absDirection.z * math.cos(yaw)
	
    return maxSpeed
		and { X = relX * 127 // 1, Y = relZ * -127 // 1 }
		or	{ X = relX, Y = relZ }
end

---@alias MarioAction number
marioAction = {
	standing = 0x0C400201,
	walking = 0x04000440,
	turningaround = 0x00000443,
	slidekick = 0x018008AA,
	grounddive = 0x00880456,
	airdive = 0x0188088A,
	airkick = 0x018008AC,
	stopsliding = 0x00000386,
	hasbowser = 0x00000391,
	releasingbowser = 0x00000392,
	softbonk = 0x010208B6,
	backwardrollout = 0x010008AD,
	forwardrollout = 0x010008A6,
	sliding = 0x008C0453,
	jump = 0x03000880,
	jump2 = 0x03000881,
	jump3 = 0x01000882,
	jump1land1 = 0x04000470,
	jump1land2 = 0x0C000230,
	jump2land1 = 0x04000472,
	jump2land2 = 0x0C000231,
	airhittingwall = 0x000008A7, -- before wall kick (press A when this action for first-frame wallkick)
	longjump = 0x03000888,
	longjumpland = 0x00000479,
	backflip = 0x01000883,
	twirling = 0x108008A4,
	punching = 0x00800457,
	groundpounding = 0x008008A9,
	groundpoundland = 0x0080023C,
}

---@return MarioAction (hexadecimal)
mario.getAction = function()
	return memory.access(mario.base + 0xC, UINT)
end

---@param action MarioAction (hexadecimal)
---@return MarioAction (hexadecimal)
mario.setAction = function(action)
	return memory.access(mario.base + 0xC, UINT, action)
end

---@param action MarioAction (hexadecimal)
---@return boolean
mario.isAction = function(action)
	return mario.getAction() == action
end

---@param actions MarioAction[] (hexadecimal)
---@return boolean
mario.isActionAny = function(actions)
	local a = mario.getAction() -- avoid allocating memory everytime
	for _, action in ipairs(actions) do
		if a == action then
			return true
		end
	end
	return false
end

--[[
mario.rotationyaw = property.new(mario.base, {
	facing = 0x2E,
	moving = 0x38,
	intended = 0x24,
	twirl = 0x3A,
	floor = 0x74,
	vel = 0x34
}, USHORT) -- ushort

mario.lives = property.new(mario.base, {
	count = 0xAD,
	displayed = 0xF0,
}, BYTE)

mario.triangles = function()
	return {
		floor = triangle.new("floor", mario),
		wall = triangle.new("wall", mario),
		ceiling = triangle.new("ceiling", mario)
	}
end]]

-- todo: add angles table
return mario