-- main.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.RL.AIRL")

local savePath = "lua/tasbots/RL/example.st1"
local dataPath = "lua/tasbots/RL/getCoin.json"
local csvPath = "lua/tasbots/RL/reward_log.csv"

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
local function getActionFromName(a)
    if a == "Left" then return joypad.left end
    if a == "Right" then return joypad.right end
    if a == "Up" then return joypad.up end
    if a == "Down" then return joypad.down end
    if a == "UpLeft" then return joypad.upleft end
    if a == "UpRight" then return joypad.upright end
    if a == "DownLeft" then return joypad.downleft end
    if a == "DownRight" then return joypad.downright end
    emu.stop("Invalid action name: " .. a)
end

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1600 or mario.getWallTriangle().exists()
end

local prevDist = nil
local prevSpeed = nil
local function rewardFormula(prevAction)
    -- # Per tick reward
    local currDist = marioObj.distanceFrom(coin)
    local distance = -(prevDist or currDist - currDist) / 5000 + 0.195 -- 0.195 is about the distance when loadstate
    prevDist = currDist

    local currSpeed = mario.speed().h
    local speed = (prevSpeed or currSpeed - currSpeed) / 10
    prevSpeed = currSpeed

    local prize = marioObj.overlapsWith(coin) and 2 or 0
    local badActionsPenalty = doingBadAction() and -2 or 0
    
    return distance + speed + prize + badActionsPenalty
end

local ai = aiFactory.new({
    alpha = 0.5,
    base_epsilon = 1.0,
    epsilonDecay = 0.99
}, actionNames,
    function()
        -- # State formula
        local dx, _, dz = marioObj.distanceXYZFrom(coin).tuple()
        local hSpeed = mario.speed().h
        return string.format("%d,%d", dx//40, dz//40,hSpeed//3)
    end, dataPath
)
ai.loadData()

local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
end

local function start()
    savestate.savefile(savePath)
end

local csvFile = io.open(csvPath, "w")
---@cast csvFile file*
csvFile:write("Episode,AvgReward,Success\n")
csvFile:flush()
csvFile:close()
csvFile = io.open(csvPath, "a")
---@cast csvFile file*

local prevState = nil
local prevAction = nil -- rewards are given one frame after the action is performed

local function update()

    if prevAction and prevState then

        local reward = rewardFormula(prevAction)
        ai.rewardPrevious(prevState, prevAction, reward)

        if joypad.contains("up") then
            printf("Rewarded previous with %.3f (trust: %.3f)\n", reward, prevState.trust[prevAction])
        end

        local failed = doingBadAction()
        if marioObj.overlapsWith(coin) or failed then
            -- logging files to .csv
            csvFile:write(string.format("%d,%.2f,%s\n", ai.episodeCounter, ai.totalTickReward, (failed and "0" or "100")))

            ai.nextEpisode(not failed, true)
            reset()

            prevState = nil
            prevAction = nil
            return -- !
        end
    end -- no prev action (begin of episode)
    
    prevState, prevAction = ai.getTickAction()
    joypad.set(getActionFromName(prevAction))

    if joypad.contains("up") then
        printf("Perfomed action: %s in [%s] (prev trust: %.3f, epsilon: %.3f)", prevAction, prevState.identifier, prevState.trust[prevAction], prevState.epsilon)
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    ai.saveData()
    csvFile:close()
end)
