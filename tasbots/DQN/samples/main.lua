-- main.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")

local savePath = "lua/tasbots/DQN/samples/example.st1"
local csvPath = "lua/tasbots/DQN/samples/reward_log.csv"

local marioObj = mario.getObj()
---@cast marioObj Object
local coin = om.getObject(44)

-- creating ai
local function inputsFormula()
    local mx, _, mz = mario.pos().tuple()
    local cx, _, cz = coin.pos().tuple()
    local dx = (cx - mx) / 2200
    local dz = (cz - mz) / 2200
    local speedInfo = mario.speed()
    -- local floor = mario.getFloorTriangle()

    return {
        mx / 2200, mz / 2200,
        dx, dz,
        speedInfo.x / 30, speedInfo.y / 30,
        mario.yawInfo().facing() / 65535,
        camera.yaw() / 65535,
        -- mario.getAction() / 0xFFFF,
        -- floor.distToMario() / floor.height(),
    }
end

local epsilonDecay, epsilonMin, learningRate = 0.99989, 0.05, 0.001
local ai = aiFactory.new(inputsFormula, 16, 4, epsilonDecay, epsilonMin, learningRate, "tanh", 4)

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1600 or
        mario.getWallTriangle().exists()
end

local prevDist = nil
local startingDist = nil
local function rewardFormula(prevAction)
    local currDist = marioObj.distanceFrom(coin)
    startingDist = startingDist or currDist
    local delta = (prevDist or currDist) - currDist
    prevDist = currDist

    local distanceReward = delta / startingDist -- normalizzato
    local prize = marioObj.overlapsWith(coin) and 10 or 0
    local bad = doingBadAction() and -1 or 0

    return distanceReward + prize + bad
end

local function outputsToAction(outputs)
    -- 4 outputs (X, Y, A, B)
    local x, y = outputs[1], outputs[2]--, outputs[3], outputs[4]
    -- printf("%d,%d", x//1, y//1)
    return {
        X = (x )//1,
        Y = (y )//1,
        -- A = a > 0.5,
        -- B = b > 0.5,
    }
end

local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
    prevDist = nil
    startingDist = nil
end

local function start()
    savestate.savefile(savePath)
end

-- local csvFile = io.open(csvPath, "w")
-- ---@cast csvFile file*
-- csvFile:write("Episode,AvgReward,Epsilon\n")
-- csvFile:flush()
-- csvFile:close()
-- csvFile = io.open(csvPath, "a")
-- ---@cast csvFile file*

local function avg(t)
    local s = 0 for _, v in ipairs(t) do s = s + v end
    return s / #t
end

local episode = 0
local rewardOfThisEpisode = 0

local delayFrames = 4
local history = {} -- { inputs, outputs, reward }

local function update()

    if #history > delayFrames then
        -- reward old action
        local old = table.remove(history, 1)
        local reward = rewardFormula(old.ACTION)
        local nextInputs = inputsFormula()
        ai.giveReward(old.STATE, old.ACTION, reward, nextInputs)

        rewardOfThisEpisode = rewardOfThisEpisode + reward

        if joypad.contains("up") then
            local outputs = outputsToAction(old.ACTION)
            printf("Rewarded action ({X=%d, Y=%d}) %d frames ago with %.3f\n", outputs.X, outputs.Y, delayFrames, reward)
        end

        local failed = doingBadAction()
        if marioObj.overlapsWith(coin) or failed then
            episode = episode + 1
            -- logging files to .csv
            -- csvFile:write(string.format("%d,%.3f,%.3f\n",
            --     episode, rewardOfThisEpisode, ai.epsilon
            -- ))

            printf("Episode %d, total reward: %.3f (epsilon: %.3f)", episode, rewardOfThisEpisode, ai.epsilon)
            reset()
            rewardOfThisEpisode = 0

            history = {}
            return -- !
        end
    end
    
    local state = inputsFormula()
    local action = ai.getBestAction()
    table.insert(history, {STATE = state, ACTION = action})

    joypad.set(outputsToAction(action))

    if joypad.contains("up") then
        local inputs = inputsFormula()
        print("Inputs = {")
        printf("    Mario Pos = {x=%.3f, z=%.3f}", inputs[1], inputs[2])
        printf("    Distance = {x=%.3f, z=%.3f}", inputs[3], inputs[4])
        printf("    Mario Speed = {x=%.3f, z=%.3f}", inputs[5], inputs[6])
        printf("    Mario Yaw = %.3f", inputs[7])
        printf("    Camera Yaw = %.3f", inputs[8])
        print("}")
        local outputs = outputsToAction(action)
        printf("Outputs = {X=%d, Y=%d}", outputs.X, outputs.Y)
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    -- csvFile:close()
end)