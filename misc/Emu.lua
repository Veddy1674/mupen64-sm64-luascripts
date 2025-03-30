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
    
    return self
end

---@type Emu
emu = Emu.new()