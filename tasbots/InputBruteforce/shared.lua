-- shared.lua - between main.lua, save.lua and playback.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")

savestateFile = "lua/tasbots/InputBruteforce/example.st1"
goodEndingFile = "lua/tasbots/InputBruteforce/goodEndings.json"
instanceCountFile = "lua/tasbots/InputBruteforce/instanceCount.txt"
infoFile = "lua/tasbots/InputBruteforce/info.json"

function reset()
    joypad.set({})
    savestate.loadfile(savestateFile)
end

-- main logic, meant to be changed

---@type Object
_marioObj = nil
---@type Object
_goalObj = nil

function init()
    _marioObj = mario.getObj()
    _goalObj = om.getObjects()[114]
end

function doingBadAction(frame)
    return _marioObj.distanceFrom(_goalObj) > 1830 or frame > 150 -- 5 seconds
end

function doingSlightlyBadAction(frame)
    return (frame > 5 and mario.speed().h < 10) -- only bans the action made and without relatives
end

function doingGoodAction()
    return _marioObj.overlapsWith(_goalObj)
end

-- used for RL only
---@param ai AIRL
---@param state AIState
---@param action string
---@param totalReward number
---@param doingBad boolean
---@param doingGood boolean
---@return number
function reward(ai, state, action, totalReward, doingBad, doingGood) -- action of the frame before, not current!
    if doingBad then return -10 end
    if doingGood then return 10 end

    local distReward = 1 - (_marioObj.distanceFrom(_goalObj) / 1830)
    local actions = string.split(action, ",")
    if actions[2] == "A" then
        -- reward all actions that contain A
        for _, dir in ipairs(_directions) do
            ai.rewardPrevious(state, dir .. ",A", -1000000000000)
            ai.rewardPrevious(state, dir, 100)
        end
        -- if state.trust["Left"] then printf("Trust of Left: %.2f", state.trust["Left"]) end
        -- if state.trust["Left,A"] then printf("Trust of Left + A: %.2f", state.trust["Left,A"]) end
    end
    -- printf("[RWD] action = %s | reward = %.2f", action, n)
    return distReward
end