-- Mario.lua

local triangle = require("mario.Triangle")
require("misc.Utils")
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
--[[
mario.speed = property.new(mario.base, {
    h = 0x54, -- main speed
    x = 0x48,
    y = 0x4C,
    z = 0x50 -- todo: add defacto, sideways, sliding speeds
}, FLOAT)

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