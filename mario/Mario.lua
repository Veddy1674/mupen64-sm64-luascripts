-- Mario.lua
local marioutils = require("mario.MarioUtils")
local triangle = require("object.Triangle")
local property = require("misc.Property")

local module = {}

module.base = 0x8033B170 -- "Mario"

-- adding getters and setters of the tables
module.pos = property.new(module.base, {
    x = 0x3C,
    y = 0x40,
    z = 0x44
}, "float", 3)

module.speed = property.new(module.base, {
    h = 0x54, -- main speed
    x = 0x48,
    y = 0x4C,
    z = 0x50 -- todo: add defacto, sideways, sliding speeds
}, "float", 2)

module.lives = property.new(module.base, {
	count = 0xAD,
	displayed = 0xF0,
}, "byte")

module.triangles = function()
	return {
		floor = triangle.new("floor", module),
		wall = triangle.new("wall", module),
		ceiling = triangle.new("ceiling", module)
	}
end

-- todo: add angles table

return module
