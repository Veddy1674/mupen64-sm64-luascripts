-- starcatch.lua

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
-- applyPerformance.setConfig({
--     disableMusic = true,
--     disablePrints = false,
--     invisibleObjects = true,
-- })
applyPerformance.setConfig("debug")

-- creating ai
local function inputsFormula()
    local pos = mario.pos()
    local starPos = star.pos()
    local origin = pos + Vector3.new(0, 80, 0)
    local dir = yawToVector(mario.yawInfo().facing())
    local rays = {}
    
    -- normalize dx, dz to [0,1]
    local delta = (starPos - pos)
    local dx = (delta.x + 1300) / 2600
    local dz = (delta.z + 1300) / 2600

    -- 8 directions (clockwise)
    local angles = {0, 45, 90, 135, 180, -135, -90, -45}
    for _, a in ipairs(angles) do
        local rad = math.rad(a)
        local s, c = math.sin(rad), math.cos(rad)
        local rotated = Vector3.new(dir.x * c - dir.z * s, 0, dir.x * s + dir.z * c)

        local hit = Raycast.multipleRayHits(
            origin, starPos, rotated,
            6, 157.25, star.hitbox().radius
        )
        table.insert(rays, hit and 1 or 0)
    end

    return {dx, dz}--, table.unpack(rays)}
end

local epsilonDecay, epsilonMin, gamma, learningRate = 0.9998, 0.05, 0.99, 0.004
local ai = aiFactory.new(inputsFormula, { 2, 24, 4 }, gamma, learningRate, epsilonDecay, epsilonMin, { "Left", "Right", "Up", "Down" }, 20000, 64)
ai.loadData(savePath)
local episode = ai.episodes

local function doingBadAction()
    return marioObj.distanceFrom(star) > 1100
end

local function rewardFormula(prevState, nextState, prevAction)
    local px, pz = prevState[1], prevState[2]
    local nx, nz = nextState[1], nextState[2]
    print(px, nx)
    local dist = ((px - nx) + (pz - nz)) * 3
    local reward = dist
    
    if marioObj.overlapsWith(star) then
        reward = 15
    elseif doingBadAction() then
        reward = -10
    end

    if joypad.get().down then
        print(reward)
    end
    return reward
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

local function reset(resetMario)
    joypad.set({})
    savestate.loadfile(savestatePath)
    applyPerformance.applyConfig(marioObj, om.getObjects(), nil)
end

local function start()
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
    camera.mode(0x0)
    f = f + 1

    -- First do action and then reward the action made 'frameDelay' frames ago.
    -- Before it was the opposite (reward, then action), this change was made to 
    -- make sure the AI gets rewarded for the last action (or else it won't know if it failed or succeeded)
    
    local state = inputsFormula()
    if joypad.get().left then print("State: " .. table.concat(state, ", ")) end
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
        local success = marioObj.overlapsWith(star)

        if success or failed then
            local finalReward = rewardFormula(old[1], nextState, old[2])
            ai.remember(old[1], old[3], finalReward, nextState)
            ai.train()

            episode = episode + 1
            printf("Episode %d, avgReward: %.2f, lr: %f, epsilon: %.2f (%s)", episode, avgReward + finalReward, ai.network.learningRate, ai.epsilon, (failed and "FAILED" or "SUCCESS"))
            ai.updateGraph(episode, avgReward)
            reset(failed)
            history = {}
            f = 0
            avgReward = 0
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
end)