-- playback.lua

require("lua.tasbots.InputBruteforce.shared")
local json = require("lib.json")
local actionInterpreter = require("tasbots.RL.actionInterpreter")

local file = io.open(goodEndingFile, "r")
if not file then emu.stop() return end

---@type string[]
local goodEndings = json.decode(file:read("*a"))

file:close()

local shortestTime, bestEnding = math.huge, nil

for _, ending in ipairs(goodEndings) do
    if #ending < shortestTime then
        shortestTime = #ending
        bestEnding = ending
    end
end

local function start()
    if not bestEnding then
        emu.stop("No good endings found!")
        return
    end

    joypad.set({})
    savestate.loadfile(savestateFile)

    printf("%d Good endings found.", #goodEndings)
    printf("Unpause game to play the best ending (%d frames)", #bestEnding)
    emu.pause()
end
---@cast bestEnding string[]

local db, db2, ended = false, false, false
local frame = 0

local function update()
    local paused = emu.isPaused()

    if not paused then
        if not db then
            db = true
            print("Playing the best ending...")
        end
        if not ended then
            frame = frame + 1
            local nextInput = bestEnding[frame]
            if nextInput == nil then
                ended = true
            else
                joypad.set(actionInterpreter.toInputs(nextInput))
            end
        else
            if not db2 then
                db2 = true
                emu.pause()
                emu.stop("Ended with success.")
            end
        end
    end
end

emu.start(start)
emu.update(update)
