-- main.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")

local savePath = "lua/tasbots/DQN/example.st1"
local csvPath = "lua/tasbots/DQN/reward_log.csv"

local marioObj = mario.getObj()
---@cast marioObj Object
local coin = om.getObjects()[44]

---@type string[]
local actionNames = {
    "Left",
    "Right",
    "Up", "UpLeft", "UpRight",
    "Down", "DownLeft", "DownRight",
}
---@param a string
---@param abs boolean
local function getActionFromName(a, abs)
    local function f(i)
        return abs and mario.getAbsoluteInputs(i) or i
    end
    if a == "Left" then return f(joypad.left) end
    if a == "Right" then return f(joypad.right) end
    if a == "Up" then return f(joypad.up) end
    if a == "Down" then return f(joypad.down) end
    if a == "UpLeft" then return f(joypad.upleft) end
    if a == "UpRight" then return f(joypad.upright) end
    if a == "DownLeft" then return f(joypad.downleft) end
    if a == "DownRight" then return f(joypad.downright) end
    emu.stop("Invalid action name: " .. a)
end

-- creating ai
local function inputsFormula()
    local dist = marioObj.distanceFrom(coin) / 1000
    local speedInfo = mario.speed()
    local dirX, _, dirZ = marioObj.distanceXZFrom(coin).normalize().tuple()

    return {
        dirX, dirZ,
        speedInfo.x / 30, speedInfo.y / 30,
        mario.yawInfo().facing() / 65535,
        camera.yaw() / 65535,
    }
end
-- print(inputsFormula())

local ai = aiFactory.new(inputsFormula, 24, actionNames, 0.9998, 0.05, 0.001, "tanh")

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1600 or
        mario.getWallTriangle().exists()
end

local prevDist = nil
local function rewardFormula(prevAction)
    -- # Per tick reward
    local currDist = marioObj.distanceFrom(coin)
    local distance = ((prevDist or currDist) - currDist) / 3000
    prevDist = currDist

    local prize = marioObj.overlapsWith(coin) and 8 or 0
    local bad = doingBadAction() and -1.5 or 0
    
    return distance + prize + bad - 0.0001
end

local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
    prevDist = nil
end

local function start()
    savestate.savefile(savePath)
end

local csvFile = io.open(csvPath, "w")
---@cast csvFile file*
csvFile:write("Episode,AvgReward,Epsilon\n")
csvFile:flush()
csvFile:close()
csvFile = io.open(csvPath, "a")
---@cast csvFile file*

local function avg(t)
    local s = 0 for _, v in ipairs(t) do s = s + v end
    return s / #t
end

local prevAction = nil -- rewards are given one frame after the action is performed
local prevInputs = nil
---@cast prevInputs number[]

local episode = 0
local rewardOfThisEpisode = 0

local function update()

    if prevAction then

        local reward = rewardFormula(prevAction)
        local nextInputs = inputsFormula()
        ai.giveReward(prevInputs, prevAction, reward, nextInputs)
        rewardOfThisEpisode = rewardOfThisEpisode + reward

        if joypad.contains("up") then
            printf("Rewarded previous action with %.3f\n", reward)
        end

        local failed = doingBadAction()
        if marioObj.overlapsWith(coin) or failed then
            episode = episode + 1
            -- logging files to .csv
            csvFile:write(string.format("%d,%.3f,%.3f\n",
                episode, rewardOfThisEpisode, ai.epsilon
            ))

            printf("Episode %d, total reward: %.3f (epsilon: %.3f)", episode, rewardOfThisEpisode, ai.epsilon)
            reset()
            rewardOfThisEpisode = 0

            prevAction = nil
            return -- !
        end
    end -- no prev action (begin of episode)
    
    prevInputs = inputsFormula()
    prevAction = ai.getBestAction()
    joypad.set(getActionFromName(prevAction, false))

    if joypad.contains("up") then
        printf("Perfomed action: %s", prevAction)
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    csvFile:close()
end)