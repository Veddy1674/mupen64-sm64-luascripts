-- shared.lua - between main.lua, save.lua and playback.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")

savestateFile = "lua/tasbots/InputBruteforce/example.st1"
goodEndingFile = "lua/tasbots/InputBruteforce/goodEndings.json"
instanceCountFile = "lua/tasbots/InputBruteforce/instanceCount.txt"
infoFile = "lua/tasbots/InputBruteforce/info.json"

function reset()
    joypad.set({})
    savestate.loadfile(savestateFile)
end

-- main logic, meant to be changed

local marioObj = nil
local goal = nil
---@cast marioObj Object
---@cast goal Object

function init()
    marioObj = mario.getObj()
    goal = om.getObjects()[52]
    ---@cast marioObj Object
end

function doingBadAction(frame)
    return marioObj.distanceFrom(goal) > 1700 or mario.isAction(marioAction.softbonk) or frame > 150 -- 5 seconds
end

function doingGoodAction()
    return marioObj.overlapsWith(goal)
end