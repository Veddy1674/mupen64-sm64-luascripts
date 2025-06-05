-- coincatch.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savestatePath = "lua/tasbots/DQN/samples/coincatch.st1"
local savePath = "lua/tasbots/DQN/samples/coincatch.json"

--! you must be in the same area of your savestate
local marioObj = mario.getObj()
local coin = om.getObject(172)
---@cast marioObj Object

local applyPerformance = require("lua.tasbots.DQN.performance")
-- applyPerformance.setConfig({
--     disableMusic = true,
--     disablePrints = false,
--     invisibleObjects = true,
-- })
applyPerformance.setConfig("debug")

-- creating ai
local function inputsFormula()
    local m = mario.pos()
    local c = coin.pos()
    local dx = math.abs(m.x - c.x) / 1300
    local dz = math.abs(m.z - c.z) / 1300

    -- local yaw = (camera.yaw() / 65535 * math.pi * 2) / (2 * math.pi)

    return { -- everything normalized to 0-1
        dx, dz, mario.yawInfo().facing() / 65535
    }
end

local epsilonDecay, epsilonMin, gamma, learningRate = 0.9998, 0.05, 0.5, 0.001
local ai = aiFactory.new(inputsFormula, { 3, 12, 4 }, gamma, learningRate, epsilonDecay, epsilonMin, { "Left", "Right", "Up", "Down" }, 20000, 64)
ai.loadData(savePath)
local episode = ai.episodes

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1000 or mario.getWallTriangle().exists()
end

local function rewardFormula(prevState, nextState, prevAction)
    local distBefore = Vector3.new(prevState[1], 0, prevState[2]).magnitude()
    local distNow = Vector3.new(nextState[1], 0, nextState[2]).magnitude()

    local delta = distBefore - distNow
    if marioObj.overlapsWith(coin) then print("ok") return 100 end
    if doingBadAction() then return -10 end

    return delta * 10
end

local function outputsToAction(output)
    if joypad.get().up then print(output) end
    return joypad[output:lower()] -- example: "UpLeft" -> joypad.upleft -> { X = -91, Y = 91 }
end

--! frameDelay shouldn't be set to zero, because of "distBefore" in reward formula could be nil or
-- represent the last frame of the previous episode
local frameDelay = 1 -- only counts at the start
-- local frameSkip = 4 -- skips reward
local history = {} -- { {prevState, prevAction, prevIndex}, ... }

-- decided externally
local minX, minZ, maxX, maxZ = -1958.787, -565.146, -1258.787, 234.854

local function reset(resetMario)
    joypad.set({})

    -- random mario position
    if resetMario then
        local x = math.randomforcefloat(minX, maxX)
        local z = math.randomforcefloat(minZ, maxZ)
        mario.pos(Vector3.new(x, mario.pos().y, z))
    end
    -- random coin position
    local x = math.randomforcefloat(minX, maxX)
    local z = math.randomforcefloat(minZ, maxZ)
    coin.pos(Vector3.new(x, coin.pos().y, z))

    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)
end

local function start()
    savestate.loadfile(savestatePath)
    reset(true)
end

local function checkStateValid(state)
    local oob = table.compare(state, function(t) return t > 1 or t < 0 end)
    if oob then
        emu.stop("State out of bounds (bigger than 1 or less than 0): " .. tostring(oob), false) -- (it saves)
        return
    end
end

local f = 0

local avgReward = 0 -- per episode
local function update()
    f = f + 1

    -- First do action and then reward the action made 'frameDelay' frames ago.
    -- Before it was the opposite (reward, then action), this change was made to 
    -- make sure the AI gets rewarded for the last action (or else it won't know if it failed or succeeded)
    
    local state = inputsFormula()
    checkStateValid(state)

    if joypad.get().up then print(state) end
    local action, index = ai.getAction(state)
    
    table.insert(history, {state, action, index})

    joypad.set(outputsToAction(action))
    if joypad.get().right then print("Action: " .. action) end
    
    if #history >= frameDelay then
        local old = table.remove(history, 1)
        local nextState = inputsFormula()
        checkStateValid(nextState)

        local failed = doingBadAction()
        local success = marioObj.overlapsWith(coin)

        if success or failed then
            local finalReward = rewardFormula(old[1], nextState, old[2])
            ai.remember(old[1], old[3], finalReward, nextState)
            ai.train()

            episode = episode + 1
            printf("Episode %d, avgReward: %.2f, lr: %f, epsilon: %.2f (%s)", episode, avgReward, ai.network.learningRate, ai.epsilon, (failed and "FAILED" or "SUCCESS"))
            ai.updateGraph(episode, avgReward)
            reset(failed)
            history = {}
            f = 0
            return --!
        end

        -- reward moved here to avoid not getting a reward for the last action of the episode
        local reward = rewardFormula(old[1], nextState, old[2])
        ai.remember(old[1], old[3], reward, nextState)
        ai.train()

        avgReward = avgReward + reward -- total
    end

    if f % 1000 == 0 then
        ai.copyTarget()
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    reset()
    if crashed then return end
    ai.saveData(savePath)
    ai.makeGraph("lua/tasbots/DQN/coincatch_reward.csv", "lua/tasbots/DQN/coincatch_epsilon.csv")
end)