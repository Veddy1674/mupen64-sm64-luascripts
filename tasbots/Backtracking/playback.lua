-- playback.lua

require("lua.misc.Utils")
local json = require("lua.lib.json")
local actionInterpreter = require("lua.tasbots.RL.actionInterpreter")

local mainSavestate = "lua/tasbots/Backtracking/slide.st1"
local savePath = "lua/tasbots/Backtracking/CCMslide.json"

local dataset = {}
local function start()
    local file = io.open(savePath, "r")
    if not file then emu.stop("No file found.") return end
    local data = json.decode(file:read("*a"))
    file:close()

    dataset = data
    emu.pause()
    savestate.loadfile(mainSavestate)
    print("Data found! Unpause to playback.")
end
local running = false

local f = 0
local function update()
    if not emu.isPaused() and not running then
        running = true
        print("Playing...")
    end
    if not running then return end

    f = f + 1
    joypad.set(actionInterpreter.toInputs(dataset[f]))
    print(dataset[f])
    if f >= #dataset then
        emu.pause()
        emu.stop("Success")
    end
end

emu.start(start)
emu.update(update)