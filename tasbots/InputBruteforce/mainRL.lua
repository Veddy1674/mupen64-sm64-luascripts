-- main.lua

local mario = require("lua.mario.Mario")
require("lua.tasbots.InputBruteforce.boring")
local actionInterpreter = require("lua.tasbots.RL.actionInterpreter")
local aiFactory = require("lua.tasbots.RL.AIRL")

local ai = aiFactory.new({
    alpha = 0.8,
    gamma = 0.9,
    base_epsilon = 1.0,
    epsilonDecay = 0.95,
    },
    function()
        -- # State formula
        local x, y, z = mario.pos().tuple()
        return ("%d,%d,%d"):format(x//400, y//400, z//400)
    end, ""
)

-- local function start()
reset()
---@diagnostic disable-next-line
_emu.set_ff(true)
-- end

local framelist = {}
local failsCount = 0
local prevAction, prevState = nil, nil
local totalReward = 0

local db = false
local function update()
    if not db then
        db = true
        init()
        return
    end

    local state, action = ai.getTickAction()
    local bad, good = doingBadAction(#framelist), doingGoodAction()

    if prevAction and prevState then
        local r = reward(ai, state, action, totalReward, bad, good)
        ai.rewardPrevious(prevState, prevAction, r)
    end

    if bad then
        failsCount = failsCount + 1
        reset()
        framelist = {}
        
        ai.nextEpisode(false, false)
        prevAction = nil
        prevState = nil
        return
    elseif good then
        printf("Found a good ending (%d frames)", #framelist)
        table.insert(goodEndings, framelist)
        framelist = {}
        reset()

        ai.nextEpisode(true, false)
        prevAction = nil
        prevState = nil
        return
    end

    prevAction = action
    prevState = state
    table.insert(framelist, action)
    joypad.set(actionInterpreter.toInputs(action))
end

-- emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    save(failsCount, #goodEndings)
    ---@diagnostic disable-next-line
    _emu.set_ff(false)
end)
