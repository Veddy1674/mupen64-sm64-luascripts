-- Main.lua
local aiFactory = require("tasbots.LR.aiRL")
local om = require("lua.object.ObjectManager")
local mathDist = require("lua.math.Distance")

-- only one action per tick
local actions = {function()
    joypad.set(joypad.right)
end, function()
    joypad.set(joypad.left)
end, function()
    joypad.set(joypad.up)
end, function()
    joypad.set(joypad.down)
end}

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

    print("It will take about " .. (maxIterations * maxTimer / 30) / (emu.getspeed() / 100) .. " seconds")
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
		-- goal reached condition
		return mathDist.marioTo(goalObj) <= 160

	end, function(ticksTaken)
		-- faster and closer = reward
		local x, y, z = ai.getDistance().tuple()
		print(ticksTaken)
        local distReward = 100 / math.floor((math.sqrt(x * x + y * y + z * z)))
        --local timePenalty = -(ticksTaken/30) * 10 -- slightly less so that distance is prioritized

		local success = ai.goalReachedCondition() and 1 or -1
		return distReward + success-- + timePenalty

	end)

    ai.loadTrustData(saveFile)
end

local function update()
    if condition() then
        return
    end

    timer = timer + 1
    local reachedGoal = ai.goalReachedCondition()

    if timer >= maxTimer or reachedGoal then
        local reward = ai.updateTrust(timer)

        local success = reachedGoal and "SUCCESS" or "FAILURE"
        print("Iteration " .. loadStateCount + 1 .. "/" .. maxIterations .. " - " .. success .. " - " ..
                  string.format("%.2f", timer / 30) .. "s" .. " - Reward: " .. reward)

        reset()
        timer = 0
    end

    ai.performAction()
end

start()

emu.atinput(function()
    update()
end)

emu.atstop(function()
    reset()
end)
