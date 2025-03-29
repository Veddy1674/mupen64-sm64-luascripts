-- Main.lua
local aiFactory = require("tasbots.LR.aiRL")
local om = require("lua.object.ObjectManager")
local mathDist = require("lua.math.Distance")
local mario = require("lua.mario.Mario")

-- only one action per tick
local actions = {
    ["right"] = function() joypad.add(joypad.right) end,
    ["left"] = function() joypad.add(joypad.left) end,
    ["up"] = function() joypad.add(joypad.up) end,
    ["down"] = function() joypad.add(joypad.down) end,
    --["A"] = function() joypad.add({A = true}) end,
}

---@type Object
local goalObj = nil
---@type AIRL
local ai = nil

local loadStateCount = 0
local maxTimer = 30 * 5 -- 5 seconds or more = reset
local timer = 0
local maxIterations = 40

local function condition()
    return ai.bestTime < 30 * 2.00
    -- return loadStateCount >= maxIterations
end

local function goalReached()
    return mathDist.marioTo(goalObj) <= 160
end

local savePath = "lua/tasbots/LR/example.st1"
-- save/load system disabled
local saveFile = nil -- "lua/tasbots/LR/example.json"

local function reset()
    timer = 0
    savestate.loadfile(savePath)

    loadStateCount = loadStateCount + 1

    if condition() then
        ai.info()
        ai.saveTrustData(saveFile)
        print("Done")
        return
    end
end

local function start()
    goalObj = om.getObjects()[43]
    print("Goal Object is a " .. goalObj.group())

    print("It will take about " .. (maxIterations * maxTimer / 30) / (emu.getSpeed() / 100) .. " seconds")
    -- when distance.marioTo(goalObj) is <= 160 the goal is reached and reset is called
    -- if it takes more than 6 seconds it gets resetted
    savestate.savefile(savePath)

    ai = aiFactory.new({
        alpha = 0.1,
        gamma = 0.9,
        epsilon = 1.0,
        epsilonDecay = 0.999,
        actions = actions
    }, actions, goalObj, function()

        local dx = math.floor(mario.pos.x / 100)
        local dy = math.floor(mario.pos.y / 100)
        local dz = math.floor(mario.pos.z / 100)
        local state = tostring(dx) .. "," .. tostring(dy) .. "," .. tostring(dz)
        return state -- e.g "1,2,3"

    end, function()
        -- Per Tick Reward

        local distReward = mario.coins --(160 * 2 - mathDist.marioTo(goalObj)) / 1000
        --print(ai.trust)
        print(distReward)
        return distReward

    end, function(ticksTaken)
        -- Per Generation Reward

        -- 150 : 2 = ticks : x --> x = 2*ticks / 150
        -- local timeReward = -1 * (2 * ticksTaken / 150)

        -- local successReward = goalReached() and 1 or -1
        return 0 -- timeReward + successReward

    end)

    ai.loadTrustData(saveFile)
end

local function update()
    if condition() then
        return
    end

    timer = timer + 1
    local reachedGoal = goalReached()
    local resetTotalTickReward = false

    if false then --timer >= maxTimer or reachedGoal then
        resetTotalTickReward = true
        local tickRewardTotal, genReward = ai.updateTrust(timer)

        local success = reachedGoal and "SUCCESS" or "FAILURE"
        print("Generation " .. loadStateCount + 1 .. "/" .. maxIterations .. " - " .. success .. " - " ..
                  string.format("%.2f", timer / 30) .. "s" .. " - Reward: " .. genReward .. " + " .. tickRewardTotal ..
                  " = " .. genReward + tickRewardTotal)

        reset()
        timer = 0
    end

    ai.performAction(resetTotalTickReward)
end

start()

emu.update(function()
    update()
end)

emu.stopped(function()
    reset()
end)
