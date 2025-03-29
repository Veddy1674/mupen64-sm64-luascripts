-- A debug lua file

local om = require("lua.object.ObjectManager")
local um = require("lua.math.UtilsMath")
local mario = require("lua.mario.Mario")

local obj = nil
local function start()
    obj = om.getObjects()[43]
end

local function update()
    obj.pos.x = obj.pos.x + math.random(-1, 1) * 2
	obj.pos.y = obj.pos.y + math.random(-1, 1) * 2
	obj.pos.z = obj.pos.z + math.random(-1, 1) * 2
end

start()

emu.update(function()
    update()
end)