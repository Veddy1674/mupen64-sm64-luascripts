-- shared.lua - between main.lua, save.lua and playback.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")

local marioObj = nil
local coin = nil
---@cast marioObj Object
---@cast coin Object

function init()
    marioObj = mario.getObj()
    coin = om.getObjects()[114]
    ---@cast marioObj Object
end
init()

function doingBadAction()
    return marioObj.distanceFrom(coin) > 1830 or mario.isAction(marioAction.softbonk)
end

function doingGoodAction()
    return marioObj.overlapsWith(coin)
end

emu.update(function()
    printf("Doing bad: %s, doing good: %s", doingBadAction() and "true" or "false", doingGoodAction() and "true" or "false")
end)