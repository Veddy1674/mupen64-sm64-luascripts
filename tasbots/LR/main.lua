-- Main.lua
local aiFactory = require("tasbots.LR.aiRL")
local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

-- only one action per tick
local actions = {
    ["right"] = function() joypad.add(joypad.right) end,
    ["left"] = function() joypad.add(joypad.left) end,
    ["up"] = function() joypad.add(joypad.up) end,
    ["down"] = function() joypad.add(joypad.down) end,
    -- ["A"] = function() joypad.add({A = true}) end,
    ["B"] = function() joypad.add({B = true}) end,
}

local savePath = "lua/tasbots/LR/example.st1"
local saveFile = nil -- "lua/tasbots/LR/example.json"
local loadStateCount, timer, maxIterations = 0, 0, 40
local previousDistance = nil

---@type AIRL
local ai = nil

---@type Object
local goalObj, marioObj = nil, nil

local function goalReached()
    ---@cast marioObj Object
    ---@cast goalObj Object
    return marioObj.overlapsWith(goalObj)
end

local function reset()
    timer, previousDistance = 0, nil
    savestate.loadfile(savePath)
    loadStateCount = loadStateCount + 1
    ai.info()
    ai.saveTrustData(saveFile)
end

local function start()
    goalObj, marioObj = om.getObjects()[43], mario.getObj()
    savestate.savefile(savePath)

    ai = aiFactory.new({
        alpha = 0.1,
        gamma = 0.9,
        epsilon = 1.0,
        epsilonDecay = 0.8,
        actions = actions
    }, actions, goalObj, function()

        -- # State formula
        return string.format("%d,%d,%d", mario.pos().x // 100, mario.pos().y // 100, mario.pos().z // 100)

    end, function()

        -- # Per tick reward
        ---@cast marioObj Object
        local currentDistance = marioObj.distanceFrom(goalObj)
        previousDistance = previousDistance ~= nil and previousDistance or currentDistance

        local reward = (previousDistance - currentDistance) / 10
        if reward == 0 then reward = -0.1 end

        previousDistance = currentDistance
        return reward

    end, function(ticksTaken)

        -- # Per generation reward
        return goalReached() and 1 or -0.1

    end)

    ai.loadTrustData(saveFile)
end

local function update()
    
    timer = timer + 1
    if timer >= 150 or goalReached() then
        local tickRewardTotal, genReward = ai.updateTrust(timer)
        print(string.format("Gen %d/%d - %s - %.2fs - Reward: %.2f", 
            loadStateCount + 1, maxIterations, 
            goalReached() and "SUCCESS" or "FAILURE",
            timer / 30, genReward + tickRewardTotal))
        reset()
    end

    ai.performAction(timer >= 150)
end

emu.start(start)
emu.update(update)
emu.stopped(reset)