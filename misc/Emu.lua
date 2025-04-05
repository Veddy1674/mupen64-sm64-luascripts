-- not a module

---@private
local stop = function(reason)
    error(reason or "\"emu.stop()\" invoked.")
end

local Emu = {}
Emu.__index = Emu

---@type nil
_emu = _G.emu

---@private
---@return Emu
function Emu.new()
    ---@class Emu
    ---@field start fun(callback: fun())
    ---@field update fun(callback: fun())
    ---@field stop fun(reason?:string)
    ---@field stopped fun(callback: fun())
    ---@field setSpeed fun(speed: number)
    ---@field getSpeed fun(): number
    ---@field frames fun(): number
    ---@field rand fun(min?:number,max?:number,...?:number): number
    local self = setmetatable({}, Emu)
    
    function self.start(callback)
        callback()
    end

    -- Calls the callback every frame (_emu.atinput)
    function self.update(callback)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        _emu.atinput(callback)
    end

    -- Stops script execution (instantly)
    function self.stop(reason)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        stop(reason)
    end

    -- Calls the callback when the emulator is stopped
    function self.stopped(callback)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        _emu.atstop(callback)
    end

    -- Expressed in percentage (100% = normal speed)
    function self.setSpeed(speed)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        _emu.speed(speed)
    end

    -- Expressed in percentage (100% = normal speed)
    function self.getSpeed()
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        return _emu.getspeed()
    end

    -- Returns the frames count (emulator itself, not game)
    function self.frames()
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        return _emu.framecount()
    end

    local randId = 1 -- Used to generate different seeds when emu.rand() is called more than once in a frame
    -- Returns a customized random number
    function self.rand(min, max, ...)
        local sum = 0
        for _, v in ipairs({...}) do
            sum = sum + v
        end
        math.randomseed(((self.frames() + 10) + os.time() * 7) + randId + sum)
        randId = randId + 1
        return min ~= nil and max ~= nil and
            math.random(min, max) or math.random()
    end
    
    return self
end

---@type Emu
emu = Emu.new()