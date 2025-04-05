-- Main.lua
local aiFactory = require("tasbots.BC.AIRL2")
local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

-- only one action per tick
-- BC stands for Behavior Cloning
local actions = {
    ["A"] = {A = true},
    ["B"] = {B = true},
    ["A and B"] = {A = true, B = true},
    ["Nothing"] = {},
}
local savePath = "lua/tasbots/PathFollow/example.st1"

local goalObj = om.getObjects()[43]
local marioObj = mario.getObj()
---@cast marioObj Object

local lastSpeed = 0

---@type AIRL2
local ai = nil
ai = aiFactory.new({
    alpha = 0.3,
    gamma = 0, -- unused
    base_epsilon = 1.0,
    epsilonDecay = 0.99
}, actions,
    function()
        -- # State formula
        return string.format("%d,%d,%d", mario.pos().x // 70, mario.pos().y // 70, mario.pos().z // 70)
        -- return string.format("%d,%d,%d,%d", mario.getAction(), mario.speed().x // 3, mario.speed().y // 3, mario.speed().z // 3)
    end,
    function()
        -- # Per tick reward
        local speedGain = mario.speed().h - lastSpeed
        lastSpeed = mario.speed().h

        local a = mario.isActionAny({marioAction.grounddive, marioAction.softbonk}) and -0.1 or 0

        return (mario.speed().h + (speedGain * 2)) + a
        -- return mario.isAction(marioAction.walking) and 10 or -10
    end,
    function()
        -- # Per generation reward
        return 0
    end,
    function(actionName)
        -- # Determine whetever some actions can be performed or not
        return true
        -- if actionName == "Nothing" then
        --     return true -- no restrictions: it might receive a low/negative reward but be forced
        -- elseif actionName == "A" then
        --     return mario.isActionAny({marioAction.standing, marioAction.walking, marioAction.grounddive})
        -- elseif actionName == "B" then
        --     -- found max vel till it dives instead of punching in https://github.com/n64decomp/sm64/blob/master/src/game/mario_actions_moving.c#L490
        --     return (mario.speed().h > 29.0 and mario.isAction(marioAction.walking)) or -- dive
        --         mario.isActionAny({marioAction.grounddive, marioAction.jump, marioAction.jump2, marioAction.jump3})
        -- elseif actionName == "A and B" then
        --     -- found max vel till it dives instead of punching in https://github.com/n64decomp/sm64/blob/master/src/game/mario_actions_moving.c#L490
        --     return mario.isActionAny({marioAction.standing, marioAction.walking})
        -- end
    end, "lua/tasbots/BC/save.json"
)

local function reset()
    joypad.set({})
    savestate.loadfile(savePath)
end

local function start()
    savestate.savefile(savePath)
end

local bestMode, can, cycled = false, true, false

local function update()
    
    
    ---@type Inputs
    local chosenActions = mario.getFollowInputs(marioObj, goalObj, true) -- direction

    table.insertAll(chosenActions, ai.getTickAction())
    joypad.set(chosenActions)
    
    if marioObj.overlapsWith(goalObj) then
        ai.nextGeneration(true) -- prints info (debugging)
        reset()
        if bestMode and not cycled then
            cycled = true
            print("BEST MODE ACTIVATED")
            ai.settings.base_epsilon = 0
            for _, s in ipairs(ai.states) do
                s.aiSettings.base_epsilon = 0
            end
        elseif cycled then
            can = true
            print("BEST MODE DISACTIVATED")
            ai.settings.base_epsilon = 1
            for _, s in ipairs(ai.states) do
                s.aiSettings.base_epsilon = 1
            end
        end
    end

    -- debugging
    if joypad.contains("up") then
        ai.infoCurrentState()
    end
    if joypad.contains("down") and can then
        can = false
        bestMode = true
        cycled = false
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    ai.saveData()
end)