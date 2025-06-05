-- main.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local aiFactory = require("lua.tasbots.RL.AIRL")

local savePath = "lua/tasbots/RL/example.st1"
local dataPath = "lua/tasbots/RL/getCoin.json"
local csvPath = "lua/tasbots/RL/reward_log.csv"

local marioObj = mario.getObj()
---@cast marioObj Object
local coin = om.getObject(44)

---@type string[]
local actionNames = {
    "Left",
    "Right",
    "Up", "UpLeft", "UpRight",
    "Down", "DownLeft", "DownRight",
}
---@param a string
local function getActionFromName(a)
    return joypad[a:lower()]
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
    
    -- print(distance + speed + prize + badActionsPenalty)
    return distance + speed + prize + badActionsPenalty
end

local ai = aiFactory.new({
    alpha = 0.5,
    base_epsilon = 1.0,
    epsilonDecay = 0.99
}, actionNames,
    function()
        -- # State formula
        local x, _, z = mario.pos().tuple()
        return string.format("%d,%d", x//500, z//500)
    end, dataPath
)
ai.loadData()

local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
end

local function start()
    _emu.set_ff(true)
    savestate.savefile(savePath)
end

local csvFile = io.open(csvPath, "w")
---@cast csvFile file*
csvFile:write("Episode,AvgReward,Success\n")
csvFile:flush()
csvFile:close()
csvFile = io.open(csvPath, "a")
---@cast csvFile file*

local history = {}
local delayedFrames = 4

local function update()

    if #history > delayedFrames then

        local old = table.remove(history, 1)
        local reward = rewardFormula(old.ACTION)
        ai.rewardPrevious(old.STATE, old.ACTION, reward)

        -- if joypad.contains("up") then
        --     printf("Rewarded previous with %.3f (trust: %.3f)\n", reward, prevState.trust[prevAction])
        -- end

        local failed = doingBadAction()
        if marioObj.overlapsWith(coin) or failed then
            -- logging files to .csv
            csvFile:write(string.format("%d,%.2f,%s\n", ai.episodeCounter, ai.totalTickReward, (failed and "0" or "100")))

            ai.nextEpisode(not failed, true)
            reset()

            history = {}
            return -- !
        end
    end

    local state, action = ai.getTickAction()
    table.insert(history, {STATE = state, ACTION = action})
    joypad.set(getActionFromName(action))

    -- if joypad.contains("up") then
    --     printf("Perfomed action: %s in [%s] (prev trust: %.3f, epsilon: %.3f)", prevAction, prevState.identifier, prevState.trust[prevAction], prevState.epsilon)
    -- end
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    ai.saveData()
    csvFile:close()
end)
