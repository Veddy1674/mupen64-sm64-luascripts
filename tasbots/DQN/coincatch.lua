-- coincatch.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savePath = "lua/tasbots/DQN/coincatch.st1"

local marioObj = mario.getObj()
local coin = om.getObjects()[172]
---@cast marioObj Object

-- creating ai
local function inputsFormula()
    local mx, _, mz = mario.pos().tuple()
    local cx, _, cz = coin.pos().tuple()
    local dx = (cx - mx)
    local dz = (cz - mz)
    local yaw = camera.yaw() / 65535 * math.pi * 2

    return { -- everything normalized to 0-1
        dx / 1000, dz / 1000,
        math.sin(yaw), math.cos(yaw)
    }
end

local epsilonDecay, epsilonMin, gamma, learningRate = 0.9998, 0.05, 0.99, 0.001
local ai = aiFactory.new(inputsFormula, { 4, 8, 12, 8, 4 }, gamma, learningRate, epsilonDecay, epsilonMin, { "Left", "Right", "Up", "Down" })
ai.copyTarget()

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1000 or mario.getWallTriangle().exists()
end

local function rewardFormula(prevState, nextState, prevAction)
    local distBefore = Vector3.new(prevState[1], 0, prevState[2]).magnitude()
    local distNow = Vector3.new(nextState[1], 0, nextState[2]).magnitude()

    -- local distReward = 0.5 - (marioObj.distanceFrom(coin) / 1000)
    local prize = marioObj.overlapsWith(coin) and 10 or 0
    local bad = marioObj.distanceFrom(coin) > 1000 and -1 or 0 -- only punish for going too far because it doesnt see walls
    local progress = (distBefore - distNow) * 10

    if joypad.get().down then print(progress) end
    return progress + prize
end

local function outputsToAction(output)
    if joypad.get().up then print(output) end
    return joypad[output:lower()] -- example: "UpLeft" -> joypad.upleft -> { X = -91, Y = 91 }
end

local frameDelay = 2
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

    history = {}
end

local function start()
    savestate.loadfile(savePath)
    reset(true)
end

local episode = 0
local f = 0

local function update()
    if #history > frameDelay - 1 then
        f = f + 1

        if f % 1000 == 0 then
            ai.copyTarget()
        end

        local old = table.remove(history, 1)
        local nextState = inputsFormula()
        local reward = rewardFormula(old[1], nextState, old[2])

        ai.remember(old[1], old[3], reward, nextState)
        ai.train()

        local failed = doingBadAction()
        if marioObj.overlapsWith(coin) or failed then
            episode = episode + 1

            printf("Episode %d, epsilon: %.2f (%s)", episode, ai.epsilon, (failed and "failed" or "SUCCESS"))

            reset(failed)
            f = 0
            return -- !
        end
    end
    
    local state = inputsFormula()
    if joypad.get().up then print(state) end
    local action, index = ai.getAction(state)
    
    table.insert(history, {state, action, index})

    joypad.set(outputsToAction(action))
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset(true)
end)