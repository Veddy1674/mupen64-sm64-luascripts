-- coinfollowmario.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savestatePath = "lua/tasbots/DQN/coinfollow.st1"
local savePath = "lua/tasbots/DQN/coinfollow.json"

--! you must be in the same area of your savestate
local marioObj = mario.getObj()
local coin = om.getObjects()[43]
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
    local mx, _, mz = mario.pos().tuple()
    local cx, _, cz = coin.pos().tuple()
    local dx = (cx - mx)
    local dz = (cz - mz)

    return { -- everything normalized to 0-1
        dx / 1200, dz / 1200
    }
end

local epsilonDecay, epsilonMin, gamma, learningRate = 0.9985, 0.05, 0.99, 0.001
local ai = aiFactory.new(inputsFormula, { 2, 8, 4 }, gamma, learningRate, epsilonDecay, epsilonMin, { "Left", "Right", "Up", "Down" })
ai.loadData(savePath)
local episode = ai.episodes

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1000
end

local function rewardFormula(prevState, nextState, prevAction)
    local distBefore = Vector3.new(prevState[1], 0, prevState[2]).magnitude()
    local distNow = Vector3.new(nextState[1], 0, nextState[2]).magnitude()

    local prize = marioObj.overlapsWith(coin) and 10 or 0
    local bad = marioObj.distanceFrom(coin) > 1000 and -1 or 0
    local progress = (distBefore - distNow) * 10

    local total = progress * 10 + prize + bad - 0.001
    if joypad.get().down then printf("Before: %.2f After: %.2f, Progress: %.2f", distBefore, distNow, progress) end
    if joypad.get().left then print("Reward: " .. total) end

    return total
end

local function moveCoin(output)
    if joypad.get().up then print(output) end

    local savedPos = coin.pos()
    if output == "Left" then
        savedPos = coin.pos() + Vector3.new(-5, 0, 0)
    elseif output == "Right" then
        savedPos = coin.pos() + Vector3.new(5, 0, 0)
    elseif output == "Up" then
        savedPos = coin.pos() + Vector3.new(0, 0, -5)
    elseif output == "Down" then
        savedPos = coin.pos() + Vector3.new(0, 0, 5)
    elseif output == "UpLeft" then
        savedPos = coin.pos() + Vector3.new(-5, 0, -5)
    elseif output == "UpRight" then
        savedPos = coin.pos() + Vector3.new(5, 0, -5)
    elseif output == "DownLeft" then
        savedPos = coin.pos() + Vector3.new(-5, 0, 5)
    elseif output == "DownRight" then
        savedPos = coin.pos() + Vector3.new(5, 0, 5)
    end
    return savedPos
end

--! frameDelay shouldn't be set to zero, because of "distBefore" in reward formula could be nil or
-- represent the last frame of the previous episode
local frameDelay = 3
local history = {} -- { {prevState, prevAction, prevIndex}, ... }

-- decided externally
local minX, minZ, maxX, maxZ = -1764.012,-1709.436,-1362.912,-702.1326

local function reset()
    -- joypad.set({})

    -- random coin position
    local x = math.randomforcefloat(minX, maxX)
    local z = math.randomforcefloat(minZ, maxZ)
    coin.pos(Vector3.new(x, coin.pos().y, z))

    applyPerformance.applyConfig(marioObj, om.getObjects(), {coin, marioObj})
end

local function start()
    savestate.loadfile(savestatePath)
    reset()

    -- QUICK PRE TRAINING
    local function preTrain()
        local state = {math.random(), math.random()}
        local targetX, targetZ = 0, 0
    
        if state[1] > state[2] then
            if state[1] > 0 then
                action = "Right"
                targetX = 1
            else
                action = "Left"
                targetX = -1
            end
        else
            if state[2] > 0 then
                action = "Down"
                targetZ = 1
            else
                action = "Up"
                targetZ = -1
            end
        end
    
        local nextState = {state[1] + 0.05 * targetX, state[2] + 0.05 * targetZ}
        -- reward by distance progress without using rewardFormula
        local reward = (Vector3.new(state[1], 0, state[2]).magnitude() - Vector3.new(nextState[1], 0, nextState[2]).magnitude()) * 10
    
        ai.remember(state, table.find(_directions, action), reward, nextState)
        ai.train()
    end
    

    local epochs = 1500
    print("Pre-training...")
    for _ = 1, epochs do
        preTrain()
    end
    print("Pre-training done! (" .. epochs .. " epochs)")
    ai.epsilon = 1.0
    ---------------
end

local function checkStateValid(state)
    if table.any(state, function(t) return t > 1 or t < 0 end) then
        -- emu.stop("State out of bounds (bigger than 1 or less than 0)", false) -- (it saves)
        return --! don't do anything if state is out of bounds
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

    coin.pos(moveCoin(action))
    -- joypad.set({}) -- avoid inputs

    if #history >= frameDelay then
        local old = table.remove(history, 1)
        local nextState = inputsFormula()
        checkStateValid(nextState)

        local failed = doingBadAction()
        local success = coin.overlapsWith(marioObj)

        if success or failed then
            local finalReward = rewardFormula(old[1], nextState, old[2])
            ai.remember(old[1], old[3], finalReward, nextState)
            ai.train()

            episode = episode + 1
            printf("Episode %d, avgReward: %.2f, lr: %f, epsilon: %.2f (%s)", episode, avgReward, ai.network.learningRate, ai.epsilon, (failed and "FAILED" or "SUCCESS"))
            ai.updateGraph(episode, avgReward)
            reset()
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
    ai.makeGraph("lua/tasbots/DQN/coinfollow_reward.csv", "lua/tasbots/DQN/coinfollow_epsilon.csv")
end)

-- a little important and nice detail to note:
-- the AI learns to understand its own and mario's hitbox without it being an input,
-- because it is trained to end as quickly as possible