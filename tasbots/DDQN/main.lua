local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")
local aiFactory = require("lua.tasbots.DDQN.AIDDQN")

local savePath = "lua/tasbots/DDQN/savestate.st1"
local bufferPath = "lua/tasbots/DDQN/replay_buffer.ddqn"
local csvPath = "lua/tasbots/DDQN/reward_log.csv"

local coin = om.getObjects()[44]
local marioObj = mario.getObj()
---@cast marioObj Object

-- Inputs per la rete
local function getState()
    local dirX, _, dirZ = marioObj.distanceXZFrom(coin).normalize().tuple()
    local speedInfo = mario.speed()
    local floor = mario.getFloorTriangle()

    return {
        dirX, dirZ,
        speedInfo.x / 30, speedInfo.y / 30,
        mario.yawInfo().facing() / 65535,
        camera.yaw() / 65535,
        mario.getAction() / 0xFFFF,
        floor.distToMario() / floor.height(),
    }
end

-- DDQN agent
local ai = aiFactory.new(#getState, 24, )

-- Reward
local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1600 or mario.getWallTriangle().exists()
end

local prevDist = nil
local function getReward()
    local currDist = marioObj.distanceFrom(coin)
    local delta = ((prevDist or currDist) - currDist) / 3000
    prevDist = currDist

    local prize = marioObj.overlapsWith(coin) and 8 or 0
    local penalty = doingBadAction() and -1.5 or 0

    return delta + prize + penalty - 0.0001
end

-- Episodio/reset
local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
    prevDist = nil
end

local function start()
    savestate.savefile(savePath)
end

-- CSV log
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

-- Ciclo principale
local episode = 0
local rewardSum = 0
local prevState = nil
local prevAction = nil

local function update()
    if prevAction then
        local reward = getReward()
        local newState = getState()
        ai.giveFeedback(prevState, prevAction, reward, newState)
        rewardSum = rewardSum + reward

        if marioObj.overlapsWith(coin) or doingBadAction() then
            episode = episode + 1
            csvFile:write(string.format("%d,%.3f,%.3f\n", episode, rewardSum, ai.epsilon))
            csvFile:flush()

            print(string.format("Ep %d | Reward: %.3f | Eps: %.4f", episode, rewardSum, ai.epsilon))
            rewardSum = 0
            prevAction = nil
            reset()
            return
        end
    end

    prevState = getState()
    prevAction = ai.getAction()
    joypad.set(prevAction)
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    csvFile:close()
end)