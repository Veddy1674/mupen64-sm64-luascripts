-- starcatch2.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savestatePath = "lua/tasbots/DQN/samples/starcatch.st1"
local savePath = "lua/tasbots/DQN/samples/starcatch.json"

local marioObj = mario.getObj()
local star = om.getObject(100)
---@cast marioObj Object

local applyPerformance = require("lua.tasbots.DQN.performance")
applyPerformance.setConfig("debug")

-- creating ai
local function inputsFormula()
    ---@type Vector3
    local diff = mario.pos() - star.pos()

    local distance = diff.magnitude()
    local normalizedDistance = distance / 1500

    local direction = diff.normalize()

    local normalizedDirX = (direction.x + 1) / 2
    local normalizedDirZ = (direction.z + 1) / 2

    return {
        clamp(normalizedDistance, 0, 1),
        clamp(normalizedDirX, 0, 1),
        clamp(normalizedDirZ, 0, 1),
        clamp(mario.yawInfo().facing() / 65535, 0, 1),
        clamp(mario.speed().h / 36, 0, 1),
    }
end

local gamma, learningRate = 0.99, 0.0001
local ai = aiFactory.new(inputsFormula, { 5, 12, 4 }, gamma, learningRate, { "Left", "Right", "Up", "Down" }, 80000, 128)
ai.loadData(savePath)
local episode = ai.episodes

local epsilonDecay, epsilonMin = 0.998, 0.05
ai.epsilon = 0

local readonly = true

local function doingBadAction()
    return marioObj.distanceFrom(star) > 1050
end

local prevDistToStar = 0

local function rewardFormula(prevState, nextState, prevAction)
    if ai.epsilon <= 0 then return nil end

    local currentDistToStar = clamp(marioObj.distanceFrom(star) / 1500, -1, 1)

    local dist = prevDistToStar - currentDistToStar
    prevDistToStar = currentDistToStar

    local reward = dist * 30

    if star.overlapsWith(marioObj) then
        reward = reward + 1
    end

    return reward - 0.01
end

local function outputsToAction(output)
    if joypad.get().up then print(output) end
    return joypad[output:lower()] -- example: "UpLeft" -> joypad.upleft -> { X = -91, Y = 91 }
end

local resetting = false -- true for one frame
local function reset()
    -- if resetting then return end

    resetting = true
    if readonly then joypad.set({}) end

    savestate.loadfile(savestatePath)
    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)
end

local function start()
    reset()
end

local function checkStateValid(state)
    local oob = table.compare(state, function(t) return t > 1 or t < 0 end)
    if oob then
        emu.stop("State out of bounds (bigger than 1 or less than 0): " .. tostring(oob), false) -- (it saves)
        return
    end
end

local rewardBuffer = 0
local transitionBuffer = {}
local bufferSize = 1

local f = 0

local avgReward = 0 -- per episode
local function update()
    if resetting then
        resetting = false
        if readonly then joypad.set({}) end
        
        -- random star pos
        star.pos(Vector3.new(
            math.randomforcefloat(-1935.442, -1627.908),
            star.pos().y,
            math.randomforcefloat(3681.15, 5202.816)
        ))
        prevDistToStar = clamp(marioObj.distanceFrom(star) / 1500, -1, 1)
        return
    end
    camera.mode(0x0)
    -- mario.speed(mario.speed().set("h", 30))
    f = f + 1

    local currentState = inputsFormula()
    checkStateValid(currentState)

    local failed = doingBadAction()
    local success = marioObj.overlapsWith(star)

    if prevState ~= nil and not (failed or success) then
        local reward = rewardFormula(prevState, currentState, ai.actions[prevActionIndex])
        if reward ~= nil then
            rewardBuffer = rewardBuffer + reward
            if joypad.get().down then print("Reward: " .. reward) end

            table.insert(transitionBuffer, {prevState, prevActionIndex, reward, currentState})
            
            if #transitionBuffer >= bufferSize then
                for _, t in ipairs(transitionBuffer) do
                    ai.remember(t[1], t[2], t[3], t[4])
                end
                ai.train()
                rewardBuffer = 0
                transitionBuffer = {}
            end
        end
    end

    local action, index = ai.getAction(currentState)
    local actionstodo = outputsToAction(action)
    if readonly then
        joypad.set(actionstodo)
    else
        joypad.addall(joypad.get(), actionstodo)
    end

    prevState = currentState
    prevActionIndex = index

    if success or failed then

        local finalReward = rewardFormula(prevState, currentState, ai.actions[prevActionIndex])
        if finalReward ~= nil then
        
            ai.remember(prevState, prevActionIndex, finalReward, currentState)
            ai.train()

            local totalEpisodeReward = rewardBuffer + finalReward
            episode = episode + 1
            printf("Episode %d, totalReward: %.2f, lr: %f, epsilon: %.2f (%s)", episode, totalEpisodeReward, ai.network.learningRate, ai.epsilon, (failed and "FAILED" or "SUCCESS"))
            ai.updateGraph(episode, totalEpisodeReward)
            ai.copyTarget()
        end

        prevState = nil
        prevActionIndex = nil
        f = 0
        avgReward = 0
        if ai.epsilon > epsilonMin then
            ai.epsilon = math.max(ai.epsilon * epsilonDecay, epsilonMin)
        end
        reset()

        return
    end

    if f % 1000 == 0 then
        ai.copyTarget()
    end

    if joypad.get().left then print("State: " .. table.concat(currentState, ", ")) end
    if joypad.get().right then print("Action: " .. action) end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    reset()
    if crashed then return end
    ai.saveData(savePath)
end)