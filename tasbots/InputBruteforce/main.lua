-- main.lua

require("lua.tasbots.InputBruteforce.boring")
local actionInterpreter = require("lua.tasbots.RL.actionInterpreter")

-- local function start()
reset()
---@diagnostic disable-next-line
_emu.set_ff(true)
-- end

local framelist = {} -- { action }
local promisingFramelist = {} -- { {state, action} }
local tempPromisingFramelist = {} -- reset every episode

local banlist = {} -- { position, action } (prevents the bot from doing "action" in "position" if it leads to reset) 
local failsCount = 0

---@type string, string
local prevState, prevAction = nil, nil
local finalDistance = math.huge

local copyChance, mutationChance, randomChance = 0.2, 0.2, 0.6

local noProgressCounter = 0 -- episodes without progress
local function checkProgress()
    -- finalDistance is previous
    -- _marioObj.distanceFrom(_goalObj) is current
    local current = _marioObj.distanceFrom(_goalObj)
    if current < finalDistance then
        -- progress was made
        promisingFramelist = table.copy(tempPromisingFramelist) -- todo check if shallow copy is enough
        finalDistance = current
        noProgressCounter = 0
        print("Found progress (" .. current .. ")")

        mutationChance = math.min(0.9, mutationChance + 0.05) -- increase
        copyChance = math.max(0.1, copyChance - 0.05) -- decrease
        randomChance = math.max(0.1, randomChance - 0.05) -- decrease
    else
        noProgressCounter = noProgressCounter + 1
        if noProgressCounter >= 10 then
            mutationChance = math.max(0.1, mutationChance - 0.05) -- decrease
            copyChance = math.min(0.9, copyChance + 0.05) -- increase
            randomChance = math.min(0.9, randomChance + 0.05) -- increase
            noProgressCounter = 0
            -- print("No progress for too long")
        end
    end
    tempPromisingFramelist = {}
end

local function banAction(state, action, firstRelatives, n)
    -- bans every action from n to action
    local function ban(s, a, relatives)
        table.insert(banlist, { s, a })
        if not relatives then return end

        -- ban variations
        local relatedAction = nil

        if string.find(a, ",") then -- simplified, only removing/adding "A": remove last 2 characters
            relatedAction = a:sub(1, -3)
        else
            relatedAction = a .. ",A"
        end
        table.insert(banlist, { s, relatedAction })
    end

    ban(state, action, firstRelatives)
    for i = 1, n do
        local frame = tempPromisingFramelist[#tempPromisingFramelist - i]
        if frame then
            ban(frame[1], frame[2], false)
        end
    end
end

local db = false
local function update()
    if not db then
        db = true
        init()
        return
    end
    if doingSlightlyBadAction(#framelist) then

        -- when true: bans relative actions, like (Left,A) and (Left), might cause lag because of i > 25 failsafe
        -- when false: less chance for the failsafe to occur, but might be slower to train
        -- when disabled: ignores slightly bad actions
        -- banAction(prevState, prevAction, false, 0)

    elseif doingBadAction(#framelist) then
        failsCount = failsCount + 1

        framelist = {}
        reset()
        -- checkProgress()

        -- ban the action itself (example: Left,A) and the related (Left), or (Left) and (Left,A)
        banAction(prevState, prevAction, true, 3)
        tempPromisingFramelist = {} -- must be reset after banAction

        return
    elseif doingGoodAction() then
        printf("Found a good ending (%d frames)", #framelist)
        table.insert(goodEndings, framelist)

        framelist = {}
        reset()
        checkProgress()

        tempPromisingFramelist = {}

        return
    end

    local mpos = _marioObj.pos()
    prevState = "[" .. mpos.x // 100 .. "," .. mpos.y // 100 .. "," .. mpos.z // 100 .. "]"

    local action = nil
    local i = 0
    repeat
        i = i + 1
        action = actionInterpreter.customRandomActions2(prevState, promisingFramelist, copyChance, mutationChance, randomChance)
    until not table.any(banlist, function(ban) return ban[1] == prevState and ban[2] ~= action end) or i > 25

    table.insert(framelist, action)
    table.insert(tempPromisingFramelist, { prevState, action })

    joypad.set(actionInterpreter.toInputs(action))

    prevAction = action
end

-- emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    save(failsCount, #goodEndings)
    ---@diagnostic disable-next-line
    _emu.set_ff(false)

    print("(Instance " .. _instance .. " out of " .. _maxInstance .. ")")
    printf("Attempts: %d, Good endings: %d, Fails: %d", failsCount + #goodEndings, #goodEndings, failsCount)
end)
