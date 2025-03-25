-- Mario.lua

local triangle = require("lua.object.Triangle")
local property = require("lua.misc.Property")

local mario = {}

mario.base = 0x8033B170 -- "Mario"

-- adding getters and setters of the tables
mario.pos = property.new(mario.base, {
    x = 0x3C,
    y = 0x40,
    z = 0x44
}, types.FLOAT, 3)

mario.speed = property.new(mario.base, {
    h = 0x54, -- main speed
    x = 0x48,
    y = 0x4C,
    z = 0x50 -- todo: add defacto, sideways, sliding speeds
}, types.FLOAT, 2)

mario.rotationyaw = property.new(mario.base, {
	facing = 0x2E,
	moving = 0x38,
	intended = 0x24,
	twirl = 0x3A,
	floor = 0x74,
	vel = 0x34
}, types.USHORT) -- ushort

mario.lives = property.new(mario.base, {
	count = 0xAD,
	displayed = 0xF0,
}, types.BYTE)

mario.triangles = function()
	return {
		floor = triangle.new("floor", mario),
		wall = triangle.new("wall", mario),
		ceiling = triangle.new("ceiling", mario)
	}
end

-- todo: add angles table
return mario