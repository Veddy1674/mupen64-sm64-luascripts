-- main.lua
-- Backtracking works by moving casually in a window of actions (e.g 8 frames)
-- and exploring all the possible actions, then comparing and choosing the best sequence of actions.
-- In a contest of SM64, it works by saving and loading states by itself, starting from a main one.
-- It previously had two savestates to rely with (if no sequences are found, try the previous save), then one,
-- and now it has a customizable array size.
-- Note that the higher the array size is, the smaller "window" can/has to be for obvious reasons, and viceversa

require("lua.lib.aiutils")
local json = require("lua.lib.json")
local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local actionInterpreter = require("lua.tasbots.RL.actionInterpreter")

local mainSavestate = "lua/tasbots/Backtracking/slide.st1"
local savePath = "lua/tasbots/Backtracking/CCMslide.json"

-- sadly a low amount of window causes lag because of the frequent savestate
-- and a high amount of window causes even more lag because of the enormous amount of possible sequences
-- (tested: with windows = 4, it goes from ~500 to ~100 fps)
local window = 16 -- should be divisible by 2
local actions = { "Left", "Right", "Up", "UpLeft", "UpRight" }
local tempSavesCount = 5
local tries -- init in start()
local onlyOptimizeDeath = true -- if true, it only backtracks when "badAction()" is true

local tempSavestates = {}
for i = 1, tempSavesCount do
    table.fastinsert(tempSavestates, "lua/tasbots/Backtracking/temp" .. i .. ".st1")
end

local function badAction()
    -- local floor = mario.getFloorTriangle()
    -- return floor.distToMario() > 250 or floor.base == 0x80193130 -- specific triangle that leads mario to the shortcut
    return mario.speed().y < -56
end

local marioObj = mario.getObj()
---@cast marioObj Object
---@type Object
local goalCoin = nil
-- in this specific savestate, a coin is created at -6488.632, -5783.54, -5670.879 (at the end of the slide)
local function goodAction()
    -- return joypad.get().up -- simplifying: human feedback
    return marioObj.overlapsWith(goalCoin)
end

local possibleActions
local prevAction
local function start()
    tries = 30 -- editable
    -- not that "tries" are used a little differently depending on whetever "onlyOptimizeDeath" is true or false
    -- check update() for more details

    if window > 16 or #actions > 5 then
        print("(WARNING) Having a window size bigger than 16 or more than 5 actions is not recommended.")
    end

    possibleActions = math.power(#actions, window)
    printf("%d possible actions in a window of %d frames: %s possible sequences per window.",
        #actions, window, tostring(possibleActions):specialFormatNumber()
    )

    if tries > possibleActions then
        print("NOTE: " .. tries .. " tries exceed the number of possible actions. Setting it to " .. possibleActions .. ".")
        tries = possibleActions
    end

    savestate.loadfile(mainSavestate)
    goalCoin = om.getObject(1) -- avoiding memory alloc

    -- save every savestate (to avoid fail to load when loading a random state)
    for i = 1, tempSavesCount do
        savestate.savefile(tempSavestates[i])
    end

    prevAction = actions[math.random(#actions)] -- optimizing, to avoid "if prevAction ~= nil" in update()
end

local function randomAction(prev)
    -- higher chance to choose a similar action to previous
    local r, r2 = math.random(), math.random(#actions) -- trying to optimize as much as possible
    if prev == "Left" then
        -- 50% Left, 30% UpLeft, 20% random
        return (r < 0.5 and "Left") or (r < 0.8 and "UpLeft") or actions[r2]
    elseif prev == "Right" then
        -- 50% Right, 30% UpRight, 20% random
        return (r < 0.5 and "Right") or (r < 0.8 and "UpRight") or actions[r2]
    elseif prev == "Up" then
        -- 50% Up, 20% UpLeft, 20% UpRight, 10% random
        return (r < 0.5 and "Up") or (r < 0.7 and "UpLeft") or (r < 0.9 and "UpRight") or actions[r2]
    elseif prev == "UpLeft" then
        -- 50% UpLeft, 30% Left, 20% random
        return (r < 0.5 and "UpLeft") or (r < 0.8 and "Left") or actions[r2]
    elseif prev == "UpRight" then
        -- 50% UpRight, 30% Right, 20% random
        return (r < 0.5 and "UpRight") or (r < 0.8 and "Right") or actions[r2]
    end
    return actions[r2]
end

local dataset = {} -- { action, action, ... }
local currentDataset = {} -- aka window
local savePointer = 1

local absF = 0 -- tracks how much time the script ran for
local f = 0
local looping = false
local currentTries = 0

local totalRecoverAttempts = 0
local totalRecoverSuccess = 0
local totalBadSequences = 0

local function update()
    absF = absF + 1

    if goodAction() then
        for _, a in ipairs(currentDataset) do
            table.insert(dataset, a)
        end

        local file = io.open(savePath, "w")
        if not file then return end
        file:write(json.encode(dataset))
        file:close()

        printf("In a total of %d actions in a window of %d frames...", #actions, window)
        printf("%d total bad sequences.", totalBadSequences)
        printf("Saved a dataset of %d frames. (It took %d frames, %.2f seconds)", #dataset, absF, absF / 30)
        printf("%d total attempts of recovering, %d successes.", totalRecoverAttempts, totalRecoverSuccess)

        savestate.loadfile(mainSavestate)
        emu.pause()
        emu.stop("Success")
        return
    end
    f = f + 1

    if looping then
        -- retry loop
        prevAction = randomAction(prevAction)
        joypad.set(actionInterpreter.toInputs(prevAction))

        if badAction() then
            f = 0
            currentDataset = {}
            currentTries = currentTries + 1
            totalRecoverAttempts = totalRecoverAttempts + 1
            -- cannot tell if loading the first, the last or a random savestate is better
            -- (logic is in "savePointer = 1" in the "if badAction" condition)
            savePointer = math.random(tempSavesCount) -- the point of "tries" might be useless now
            savestate.loadfile(tempSavestates[savePointer]) -- previous logic: load first save, then second...
            return
        elseif f > window then
            looping = false
            totalRecoverSuccess = totalRecoverSuccess + 1
            -- print("Recovered after " .. currentTries .. " tries.")
        end
        table.insert(currentDataset, prevAction)

        local actualTries = (savePointer == tempSavesCount) and clamp(tries * 2, tries, possibleActions) or tries
        if currentTries >= actualTries then
            -- emu.stop("Unable to recover after " .. tries .. " retries.")
            savePointer = math.random(tempSavesCount) -- also random
            if savePointer > tempSavesCount then
                if tries == possibleActions then
                    emu.stop("Unable to recover in any savestate. (Try increasing the number of savestates count)")
                    return
                end
                savePointer = math.random(tempSavesCount) -- also random
            end
            savestate.loadfile(tempSavestates[savePointer])
            f = 0
        end

        return
    end

    -- normal mode
    joypad.set(actionInterpreter.toInputs(prevAction))
    if badAction() then
        currentDataset = {} -- useless?
        -- print("Bad action sequence found")
        totalBadSequences = totalBadSequences + 1
        looping = true
        currentTries = 0
        savePointer = math.random(tempSavesCount) -- random
        return
    end

    prevAction = randomAction(prevAction)
    table.fastinsert(currentDataset, prevAction)

    if f % window == 0 then
        f = 0
        savePointer = savePointer + 1
        if savePointer > tempSavesCount then
            savePointer = 1
        end
        savestate.savefile(tempSavestates[savePointer])
        for _, a in ipairs(currentDataset) do
            table.fastinsert(dataset, a)
        end
        currentDataset = {}
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    
end)