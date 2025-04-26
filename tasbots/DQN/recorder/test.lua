-- test.lua

local json = require("lua.lib.json")
require("lua.tasbots.RL.actionInterpreter")
require("lua.tasbots.DQN.recorder.shared")
require("lua.misc.Utils")
local aiFactory = require("tasbots.DQN.AIDQN")

local alloutputs = {}
for i, direction in ipairs({"Left", "Right", "Up", "Down", "UpLeft", "UpRight", "DownLeft", "DownRight", "None"}) do
    local name = direction
    for j, action2 in ipairs({"", "A", "B", "Z"}) do
        for k, action3 in ipairs({"", "A", "B", "Z"}) do
            for l, action4 in ipairs({"", "A", "B", "Z"}) do
                table.insert(alloutputs, name .. (action2 == "" and "" or "," .. action2) .. (action3 == "" and "" or "," .. action3) .. (action4 == "" and "" or "," .. action4))
            end
        end
    end
end
-- 9x4x4 = 144 outputs

local function outputToAction(output) -- e.g output: "Left,A,Z"
    local A = output:find(",A")
    local B = output:find(",B")
    local Z = output:find(",Z")
    local direction = output:split(",")[1]

    local base = joypad[direction:lower()]
    local actions = { X =  base.X, Y = base.Y, A = false, B = false, Z = false }
    if A then actions.A = true end
    if B then actions.B = true end
    if Z then actions.Z = true end

    return actions
end

local ai = aiFactory.new(inputsFormula, { 2, 8, #alloutputs }, 0.99, 0.001, 0.999, 0.05, alloutputs)
ai.loadData()

local playing
local function start()
    playing = false

    print("Training AI from found dataset...")
    -- training AI from saved dataset
    local file = io.open(savePath, "r")
    if not file then return end
    local data = json.decode(file:read("*a"))
    if not data or #data == 0 then emu.stop("Corrupted or empty dataset") return end
    file:close()

    for frame, info in ipairs(data) do
        if frame > 1 then
            local nextState = info.state
            local prevState = data[frame-1].state
            local action = info.action
            local actionIndex = table.find(alloutputs, action)
            ai.remember(prevState, actionIndex, 1, nextState)
            ai.train()
        end -- skipping first frame (so that "nextState" can be a thing, frameDelay would be 1)
    end
    ai.epsilon = 0.1
    print("Training done!")
    print("Unpause to make the AI play (epsilon = " .. ai.epsilon .. ")")
end

local function update()
    if not emu.isPaused() and not playing then
        playing = true
    end
    if not playing then return end

    joypad.set(outputToAction(ai.getAction(inputsFormula())))
    if doingGoodAction() then
        playing = false
        emu.stop("Done")
        return
    end
    if doingBadAction() then
        emu.stop("Did a bad action, this shouldn't ever happen, dataset is probably corrupted.")
        return
    end
end

emu.start(start)
emu.update(update)