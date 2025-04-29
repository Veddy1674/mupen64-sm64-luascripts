-- test.lua

local json = require("lua.lib.json")
require("lua.tasbots.RL.actionInterpreter")
require("lua.tasbots.DQN.recorder.shared")
require("lua.misc.Utils")
local aiFactory = require("tasbots.DQN.AIDQN")

local alloutputs = {}
for i, direction in ipairs({"Left", "Right", "Up", "Down", "UpLeft", "UpRight", "DownLeft", "DownRight", "None"}) do
    local name = direction
    -- for j, action2 in ipairs({"", "A", "B", "Z"}) do
    --     for k, action3 in ipairs({"", "A", "B", "Z"}) do
    --         for l, action4 in ipairs({"", "A", "B", "Z"}) do
    --             table.insert(alloutputs, name .. (action2 == "" and "" or "," .. action2) .. (action3 == "" and "" or "," .. action3) .. (action4 == "" and "" or "," .. action4))
    --         end
    --     end
    -- end
    for j, action2 in ipairs({"", "A"}) do
        -- for k, action3 in ipairs({"", "B"}) do
        --     table.insert(alloutputs, name .. (action2 == "" and "" or "," .. action2) .. (action3 == "" and "" or "," .. action3))
        -- end
        table.insert(alloutputs, name .. (action2 == "" and "" or "," .. action2))
    end
end
-- A,B,Z = 9x2x2x2 = 72 outputs
-- A,B = 9x2x2 = 36 outputs
-- A = 9x2 = 18 outputs

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

local ai = aiFactory.new(inputsFormula, { #inputsFormula(), 32, #alloutputs }, 0.99, 0.001, 0.9998, 0.05, alloutputs)
ai.loadData()

local playing
local function start()
    playing = false

    -- training AI from saved dataset
    local file = io.open(savePath, "r")
    if not file then emu.stop("File " .. savePath .. " not found") return end
    local data = json.decode(file:read("*a"))
    if not data or #data == 0 then emu.stop("Corrupted or empty dataset") return end
    file:close()
    
    print("Training AI from found dataset...")
    for frame, info in ipairs(data) do
        if frame > 1 then
            local nextState = info[1]
            local prevState = data[frame-1][1]
            local action = info[2]
            local actionIndex = table.find(alloutputs, action)
            ai.remember(prevState, actionIndex, info[3], nextState)
            ai.train()
        end -- skipping first frame (so that "nextState" can be a thing, frameDelay would be 1)
    end
    ai.epsilon = 0
    print("Training done!")
    print("Unpause to make the AI play (epsilon = " .. ai.epsilon .. ")")
    emu.pause()
    reset()
end

local function update()
    if not emu.isPaused() and not playing then
        playing = true
    end
    if not playing then return end

    joypad.set(outputToAction(ai.getAction(inputsFormula())))
    if doingGoodAction() then
        playing = false
        -- replay (doesn't affect epsilon)
        print("FAIL, unpause to replay")
        emu.pause()
        reset()
        return
    end
    if doingBadAction() then
        playing = false
        -- replay (doesn't affect epsilon)
        print("FAIL, unpause to replay")
        emu.pause()
        reset()
        return
    end
end

emu.start(start)
emu.update(update)