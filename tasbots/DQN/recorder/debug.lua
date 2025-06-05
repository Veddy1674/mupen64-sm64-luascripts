-- test.lua

require("lua.tasbots.RL.actionInterpreter")
require("lua.tasbots.DQN.recorder.shared")
require("lua.misc.Utils")
local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")

local triangle = mario.getFloorTriangle()
local v1, v2, v3 = triangle.vertices().tuple()
local c1, c2, c3 =
    om.spawnObject("Coin", v1),
    om.spawnObject("Coin", v2),
    om.spawnObject("Coin", v3)
memory.access(c1.base + 0x9C, INT, -1) -- disable collision
memory.access(c2.base + 0x9C, INT, -1) -- disable collision
memory.access(c3.base + 0x9C, INT, -1) -- disable collision

local prevTriangle = mario.getFloorTriangle()
emu.update(function()
    local thisTriangle = mario.getFloorTriangle()
    if thisTriangle.base ~= prevTriangle.base then
        local v1, v2, v3 = thisTriangle.vertices().tuple()
        c1.pos(v1)
        c2.pos(v2)
        c3.pos(v3)

        print("Triangle changed.")
        prevTriangle = thisTriangle
    end
end)