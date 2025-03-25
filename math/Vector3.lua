-- Vector3.lua

---@class Vector3
---@field x number
---@field y number
---@field z number
---@field clone fun():Vector3
---@field tuple fun():number, number, number
Vector3 = {}
Vector3.__index = Vector3

---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3.new(x, y, z)
    local self = setmetatable({}, Vector3)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0

    ---@return Vector3
    function self.clone()
        return Vector3.new(self.x, self.y, self.z)
    end

    ---@return number, number, number
    function self.tuple()
        return self.x, self.y, self.z
    end

    return self
end