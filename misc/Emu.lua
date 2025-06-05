-- not a module

---@private
local stop = function(reason)
    error(reason or "\"emu.stop()\" invoked.")
end

-- local function deleteContents(folder)
--     os.execute("del /Q \"" .. folder .. "\"")
-- end

local bitmap = require("lua.lib.bitmap")

---@class Emu
---@field start fun(callback: fun())
---@field update fun(callback: fun())
---@field atUpdateScreen fun(callback: fun())
---@field stop fun(reason?:string, setCrashed?: boolean)
---@field stopped fun(callback: fun(crashed: boolean))
---@field setSpeed fun(speed: number)
---@field getSpeed fun(): number
---@field frames fun(): number
---@field pause fun(pause?: boolean)
---@field isPaused fun(): boolean
---@field screenshot fun(path?:string): file*
---@field screenshotRaw fun(path?:string)
--@field saveScreenAsBmp fun(saveFilePath?: string): nil file*
--@field getGrayImageInfo fun(file: file*): nil number[], number, number
---@field crashed boolean
local Emu = {}
Emu.__index = Emu

---@type nil
_emu = _G.emu

---@diagnostic disable: need-check-nil, undefined-field
---@private
---@return Emu
function Emu.new()
    local self = setmetatable({}, Emu)
    
    function self.start(callback)
        callback()
    end

    -- Calls the callback every frame (_emu.atinput)
    function self.update(callback)
        _emu.atinput(callback)
    end

    -- Calls the callback every time the screen is updated (_emu.atupdatescreen)
    function self.atUpdateScreen(callback)
        _emu.atupdatescreen(callback)
    end

    self.crashed = false
    -- Stops script execution (instantly, calls emu.stopped(callback) if any)
    function self.stop(reason, setCrashed)
        stop(reason) -- using _G.stop() might not work in some versions
        self.crashed = (setCrashed == nil) and false or setCrashed -- note that this flag won't work if the script crashes before emu.stop() is called
    end

    -- Calls the callback when the emulator is stopped
    function self.stopped(callback)
        _emu.atstop(function() callback(self.crashed) end)
    end

    -- Expressed in percentage (100% = normal speed)
    function self.setSpeed(speed)
        _emu.speed(speed)
    end

    -- Expressed in percentage (100% = normal speed)
    function self.getSpeed()
        return _emu.getspeed()
    end

    -- Returns the frames count (emulator itself, not game)
    function self.frames()
        return _emu.framecount() -- samplecount?
    end

    -- in the new versions _emu.pause(void) pauses the game but crashes when stopping the script
    -- in the version 1.1.9 it seems to be opposite?
    function self.pause(pause)
        pause = (pause == nil) and true or pause
        _emu.pause(not pause)
    end

    function self.isPaused()
        return _emu.getpause()
    end

    -- Saves a screenshot of the game in the current frame as a .bmp, with black borders
    function self.screenshot(path)
        returnFile = returnFile or false
        path = path or "screenshots/"

        _emu.screenshot(path)
        ---@type file*
        return io.open(path, "r")
    end

    function self.screenshotRaw(path) -- "optimized", doesn't return the file
        path = path or "screenshots/"
        _emu.screenshot(path)
    end

    -- Might be unsafe: make sure to close the file when no more using it
    -- function self.saveScreenAsBmp(saveFilePath)
        -- saveFilePath = saveFilePath or "lua/misc/temp/"
        -- pause = (pause == nil) and true or pause

        -- -- if file doesn't end with /
        -- if saveFilePath:sub(-1) ~= "/" then emu.stop("Invalid format in emu.readScreenAsBmp(), it should end with '/'") end

        -- -- if pause then self.pause() end

        -- _emu.screenshot(saveFilePath) -- saves a screenshot of the game as a .bmp
        -- local screenshot, i = nil, 0
        -- repeat -- file creation should be instant, but using a loop for safety
        --     screenshot = io.open(saveFilePath .. "screen00.bmp", "r")
        --     i = i + 1
        --     if i > 480 then
        --         emu.stop("Screenshot not found in '" .. saveFilePath .. "' (timeout)")
        --     end
        -- until screenshot ~= nil
        -- screenshot:close()

        -- -- if pause then self.pause(false) end

        -- ---@cast screenshot file*
        -- return saveFilePath .. "screen00.bmp"
        -- return nil
    -- end

    -- Returns pixel, height and width of the image and closes the file
    -- function self.getGrayImageInfo(file)
        -- local data = bitmap.from_file(file)

        -- ---@type number[]
        -- local pixels = {}
        -- local h, w = data.height, data.width
        -- -- pixels[1], _, _, _ = data:get_pixel(w-10, h-10)
        -- data:set_pixel(20, 60, 0, 0, 0, 255)
        
        -- for row = 1, w do
        --     for col = 1, h do
        --         local r, g, b = data:get_pixel(col, row)
        --         pixels[(row - 1) * w + col] = (r + g + b) // 3
        --     end
        -- end
        
        -- return pixels, w, h
        -- return nil
    -- end

    -- function self.convertToBlackWhite(inputPath, outputPath, threshold)
    --     threshold = threshold or 128

    --     local bmpData = bitmap.open(inputPath)

    --     local w, h = bmpData.width, bmpData.height

    --     for y = 1, h do
    --         for x = 1, w do
    --             local r, g, b = bmpData:get_pixel(x, y)
    --             local gray = (r + g + b) / 3
    --             local value = (gray > threshold) and 255 or 0
    --             -- bmpData:set_pixel(x, y, value, value, value)
    --         end
    --     end

        -- local bwStr = bmpData:tostring()
        -- local out = io.open(outputPath, "wb")
        -- out:write(bwStr)
        -- out:close()

    --     print("saved:", outputPath)
    -- end

    return self
end
---@diagnostic enable: need-check-nil, undefined-field

---@type Emu
emu = Emu.new()