-- shared.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local applyPerformance = require("lua.tasbots.DQN.performance")

local marioObj = mario.getObj()
---@cast marioObj Object

applyPerformance.setConfig({
    disableMusic = true,
    disablePrints = false,
    invisibleObjects = false,
})
applyPerformance.applyConfig(marioObj, om.getObjects(), nil)

savestatePath = "lua/tasbots/DQN/recorder/getcoins.st1"
savePath = "lua/tasbots/DQN/recorder/getcoins.json"
recordCount = 15

local prevCoinCount = 0

function reset()
    savestate.loadfile(savestatePath)
    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)

    prevCoinCount, prevDistance, targetCoin = 0, math.huge, nil
end

function inputsFormula()
    local mx, _, mz = mario.pos().tuple()
    local mspeed = mario.speed()
    
    local nearestCoinDist = math.huge -- presuming a coin is always found
    for _, coin in pairs(om.getObjects()) do
        if coin.isA("Coin") then
            local dist = coin.distanceFrom(marioObj)
            if dist < nearestCoinDist then
                nearestCoinDist = dist
            end
        end
    end

    return {
        mx / 3000, mz / 3000,
        nearestCoinDist / 3000,
        mspeed.x / 32, mspeed.y / 32, mspeed.z / 32, mspeed.h / 32,
        mario.coinInfo().count() / 5,
    }
end

function simplereward(state, output)
    local reward = (mario.coinInfo().count() > prevCoinCount) and 5 or -0.001
    
    prevCoinCount = mario.coinInfo().count()
    return reward
end

function doingBadAction()
    return mario.getWallTriangle().exists()
end

function doingGoodAction()
    return mario.coinInfo().count() >= 5
end