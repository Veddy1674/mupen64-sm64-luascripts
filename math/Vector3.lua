-- Vector3.lua

---@class Vector3
---@field x number
---@field y number
---@field z number
---@field clone fun():Vector3
---@field tuple fun():number, number, number
---@field info fun(decimals?:integer):string
---@field equals fun(other:Vector3):boolean
---@field set fun(arg:string, val:number):Vector3
---@field distance fun(other:Vector3):number
---@field normalize fun():Vector3
---@field magnitude fun():number
Vector3 = {}
Vector3.__index = Vector3

---@param x? number
---@param y? number
---@param z? number
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

    function self.info(decimals)
        decimals = decimals and decimals or -1
        local decText = decimals >= 0 and ("%." .. decimals .. "f") or "%f"
        return string.format("{x=" .. decText .. ", y=" .. decText .. ", z=" .. decText .. "}", self.x, self.y, self.z)
    end

    function self.equals(other)
        return self == other
    end

    function self.set(arg, val)
        local new = self.clone()
        new[arg] = val
        return new
    end

    function self.distance(other)
        return math.sqrt((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)
    end

    function self.normalize()
        local length = self.distance(Vector3.new())
        if length > 0 then
            return Vector3.new(self.x / length, self.y / length, self.z / length)
        end
        return Vector3.new()
    end

    function self.magnitude()
        return math.sqrt(self.x^2 + self.y^2 + self.z^2)
    end
    
    return self
end

-- override == operator
function Vector3.__eq(a, b)
    if getmetatable(a) ~= Vector3 or getmetatable(b) ~= Vector3 then
        return false
    end
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function Vector3.__add(a, b)
    return Vector3.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3.__sub(a, b)
    return Vector3.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- vector3-number
function Vector3.__mul(a, b)
    return Vector3.new(a.x * b, a.y * b, a.z * b)
end

-- also works vector3 // number
function Vector3.__div(a, b)
    return Vector3.new(a.x / b, a.y / b, a.z / b)
end