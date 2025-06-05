-- screenshotcapture.lua - Captures the screen by saving .bmp files

require("lua.misc.Utils")

local frames = 300
local path = "screenshots/whomp1/" -- it can create folders that do not exist

local f = 0
emu.start(function()
    -- 30 frames = 1s, 300 frames = 10s, 3000 frames = 100s
    printf("Going to capture for %d frames (%dh,%dm,%.2fs) or until 'up' is pressed", frames, frames/30/30//30, frames/30//30, frames/30)
    print("You can load a savestate right now before starting, unpause to begin")
    emu.pause()
end)

local sub = 1 -- first set of 99 screenshots and so on...
local scount = -1 -- count of current screen id
local recording = false
emu.update(function()
    if not emu.isPaused() and not recording then
        recording = true
        print("Recording started.")
    end
    if not recording then return end

    f = f + 1
    if f > frames or joypad.get().up then
        printf("%d screenshots have been saved (0-%d), for a total of %dh,%dm,%.2fs", f, f-1, f/30/30//30, f/30//30, f/30)
        emu.stop("Success")
        return
    end

    local subfolder = "_" .. tostring(sub) .. "/"
    scount = scount + 1
    if scount == 99 then
        sub = sub + 1
        scount = 0
    end
    emu.screenshot(path .. subfolder)
end)
-- Not working, see next "avicapture.lua"