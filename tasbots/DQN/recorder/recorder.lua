-- recorder.lua - it's meant to represent supervised learning

local json = require("lua.lib.json")
require("lua.tasbots.RL.actionInterpreter")
require("lua.tasbots.DQN.recorder.shared")

local function outputToAction(output)
    local x, y = output.X, output.Y
    local threshold = 60

    -- quite trash code
    local action = nil
    if math.abs(x) < threshold and y > threshold then
        action = "Up"
    elseif math.abs(x) < threshold and y < -threshold then
        action = "Down"
    elseif x < -threshold and math.abs(y) < threshold then
        action = "Left"
    elseif x > threshold and math.abs(y) < threshold then
        action = "Right"
    elseif x > threshold and y > threshold then
        action = "UpRight"
    elseif x < -threshold and y > threshold then
        action = "UpLeft"
    elseif x > threshold and y < -threshold then
        action = "DownRight"
    elseif x < -threshold and y < -threshold then
        action = "DownLeft"
    elseif x == 0 and y == 0 then
        action = "None"
    end
    if action == nil then
        emu.stop("Invalid action: (X = " .. output.X .. ", Y = " .. output.Y .. ")", true)
    end
    return action .. (output.A and ",A" or "") .. (output.B and ",B" or "") .. (output.Z and ",Z" or "")
end

local function saveDataset(data)
    local file = io.open(savePath, "w")
    if not file then return end
    file:write(json.encode(data))
    file:close()
    print("Recording saved to " .. savePath)
end

local recording, db
local function start()
    recording, db = false, false
    reset()
    print("Unpause to start recording.")
    emu.pause()
end

local dataset = {} -- { [1] = {state, action}, [2] = {...} } where [n] is the frame
local currentDataset = {}
local f = 0

local function update()
    if not emu.isPaused() and not db then
        db = true
        recording = true
        print("Recording started.")
    end
    if not recording then return end

    f = f + 1

    if doingBadAction() then
        print("Did a bad action, aborting and resetting current dataset.")
        start()
        return
    end

    local state = inputsFormula()
    local output = joypad.get()

    table.insert(currentDataset, { state, outputToAction(output) })

    if doingGoodAction() then
        for _, v in ipairs(currentDataset) do
            table.insert(dataset, { v[1], v[2] })
        end
        currentDataset = {}

        if recordCount <= 1 then
            saveDataset(dataset) -- prints success
            emu.stop("Success.", false)
        else
            recordCount = recordCount - 1
            print("Recording finished, " .. recordCount .. " left.")
        end
        start()
        return
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    reset()
end)