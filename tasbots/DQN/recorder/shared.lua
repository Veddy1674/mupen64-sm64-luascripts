-- shared.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local applyPerformance = require("lua.tasbots.DQN.performance")

local marioObj = mario.getObj()
local coin = om.getObjects()[43]
---@cast marioObj Object

applyPerformance.setConfig({
    disableMusic = true,
    disablePrints = false,
    invisibleObjects = false,
})
applyPerformance.applyConfig(marioObj, om.getObjects(), nil)

savestatePath = "lua/tasbots/DQN/recorder/getcoins.st1"
savePath = "lua/tasbots/DQN/recorder/getcoins.json"
recordCount = 3

function reset()
    savestate.loadfile(savestatePath)
    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)
end

function inputsFormula()
    local mx, _, mz = mario.pos().tuple()
    return {
        mx / 3000, mz / 3000
    }
end

function doingBadAction()
    return mario.getWallTriangle().exists()
end

function doingGoodAction()
    return mario.coinInfo().count() >= 5
end