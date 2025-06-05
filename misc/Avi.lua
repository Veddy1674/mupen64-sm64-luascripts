-- not a module

---@class Avi
---@field startCapture fun(file:string)
---@field stopCapture fun()
local Avi = {}
Avi.__index = Avi

---@type nil
_avi = _G.avi

---@diagnostic disable: need-check-nil, undefined-field
---@private
---@return Avi
function Avi.new()
    local self = setmetatable({}, Avi)
    
    -- Serves as a wrapper (for intellisense plugins)
    function self.startCapture(file)
        _avi.startcapture(file)
    end

    -- Serves as a wrapper (for intellisense plugins)
    function self.stopCapture()
        _avi.stopcapture()
    end

    return self
end
---@diagnostic enable: need-check-nil, undefined-field

---@type Avi
avi = Avi.new()