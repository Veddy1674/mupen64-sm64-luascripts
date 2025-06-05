-- Vertices.lua - made for readonly purposes

---@alias point "x1"|"x2"|"x3"|"y1"|"y2"|"y3"|"z1"|"z2"|"z3"

---@class Vertices
---@field p1 Vector3
---@field p2 Vector3
---@field p3 Vector3
---@field tuple fun():Vector3, Vector3, Vector3
---@field equals fun(other:Vertices):boolean
---@field mid fun():Vector3
Vertices = {}
Vertices.__index = Vertices

---@param v Vertices
---@param n string
---@return Vector3
local function nameToAxis(v, n)
    local num = n:sub(2, 2)
    -- n is axis name, num is the number after the axis (e.g x1, y3...)
    return v["p" .. num][n] -- "x3" -> "p3.x"
end

---@param p1? Vector3
---@param p2? Vector3
---@param p3? Vector3
---@return Vertices
function Vertices.new(p1, p2, p3)
    local self = setmetatable({}, Vertices)
    self.p1 = p1 or Vector3.new()
    self.p2 = p2 or Vector3.new()
    self.p3 = p3 or Vector3.new()

    ---@return Vector3, Vector3, Vector3
    function self.tuple()
        return self.p1, self.p2, self.p3
    end

    function self.equals(other)
        return self == other
    end

    function self.mid()
        return Vector3.new(
            (self.p1.x + self.p2.x + self.p3.x) / 3,
            (self.p1.y + self.p2.y + self.p3.y) / 3,
            (self.p1.z + self.p2.z + self.p3.z) / 3
        )
    end

    return self
end

-- override == operator
function Vertices.__eq(a, b)
    if getmetatable(a) ~= Vertices or getmetatable(b) ~= Vertices then
        return false
    end
    return a.p1 == b.p1 and a.p2 == b.p2 and a.p3 == b.p3
end