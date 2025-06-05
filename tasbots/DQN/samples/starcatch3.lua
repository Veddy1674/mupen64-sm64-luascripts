-- starcatch3.lua - this one uses -1 to 1 normalized inputs instead of 0-1, along with other small changes

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savestatePath = "lua/tasbots/DQN/samples/starcatch.st1"
local savePath = "lua/tasbots/DQN/samples/starcatch_v3.json"

local marioObj = mario.getObj()
local star = om.getObject(100)
---@cast marioObj Object

local applyPerformance = require("lua.tasbots.DQN.performance")
applyPerformance.setConfig("debug")

-- creating ai
local function inputsFormula()
    local mpos = mario.pos()
    local spos = star.pos()
    local diff = mpos - spos
    return {
        clamp(diff.x / 1500, -1, 1),
        clamp(diff.z / 1500, -1, 1),
        clamp(mario.yawInfo().facing() / 32767.5 - 1, -1, 1),
        clamp(mario.speed().h / 36, -1, 1),
        clamp(mpos.y / 3000, -1, 1),
    }
end

local gamma, learningRate = 0.99, 0.0001
local ai = aiFactory.new(inputsFormula, { 5, 16, 4 }, gamma, learningRate, { "Left", "Right", "Up", "Down" }, 80000, 128)
ai.loadData(savePath)
local episode = ai.episodes

local epsilonDecay, epsilonMin = 0.997, 0.02
ai.epsilon = 0

local readonly = true
local prevDist = 0

local function rewardFormula()
    if ai.epsilon <= 0 then return nil end

    local dist = marioObj.distanceFrom(star)
    local reward = (prevDist - dist) * 0.05
    prevDist = dist
    if star.overlapsWith(marioObj) then reward = reward + 1 end
    return reward - 0.01
end

local function outputsToAction(output)
    return joypad[output:lower()]
end

local resetting = false
local function reset()
    resetting = true
    if readonly then joypad.set({}) end
    savestate.loadfile(savestatePath)
    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)
end

local function start()
    reset()
    emu.setSpeed(111111)
end

local rewardBuffer = 0
local transitionBuffer = {}
local bufferSize = 1
local f = 0
local function update()
    if resetting then
        resetting = false
        if readonly then joypad.set({}) end
        star.pos(Vector3.new(math.randomforcefloat(-1935.4, -1627.9), star.pos().y, math.randomforcefloat(3681.1, 5202.8)))
        prevDist = marioObj.distanceFrom(star)
        return
    end
    camera.mode(0x0)
    f = f + 1

    local currentState = inputsFormula()
    local failed = marioObj.distanceFrom(star) > 1200
    local success = star.overlapsWith(marioObj)

    if prevState and not (failed or success) then
        local reward = rewardFormula()
        if reward ~= nil then
            rewardBuffer = rewardBuffer + reward
            table.insert(transitionBuffer, {prevState, prevActionIndex, reward, currentState})
            if #transitionBuffer >= bufferSize then
                for _, t in ipairs(transitionBuffer) do
                    ai.remember(t[1], t[2], t[3], t[4])
                end
                ai.train()
                transitionBuffer = {}
            end
        end
    end

    local action, index = ai.getAction(currentState)
    local joy = outputsToAction(action)
    if readonly then joypad.set(joy) else joypad.addall(joypad.get(), joy) end

    prevState = currentState
    prevActionIndex = index

    if success or failed then
        local finalReward = rewardFormula()
        if finalReward ~= nil then
            ai.remember(prevState, prevActionIndex, finalReward, currentState)
            ai.train()

            local totalReward = rewardBuffer + finalReward
            episode = episode + 1
            printf("Episode %d, reward: %.2f, eps: %.3f (%s)", episode, totalReward, ai.epsilon, (failed and "FAIL" or "OK"))
            ai.updateGraph(episode, totalReward)
            ai.copyTarget()
        end
        if ai.epsilon > epsilonMin then ai.epsilon = math.max(ai.epsilon * epsilonDecay, epsilonMin) end
        rewardBuffer = 0
        prevState, prevActionIndex = nil, nil
        reset()
        return
    end

    if f % 1000 == 0 and ai.epsilon > epsilonMin then ai.copyTarget() end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    reset()
    if crashed then return end
    ai.saveData(savePath)
end)