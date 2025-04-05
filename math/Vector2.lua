-- Vector2.lua - Not correlated with Vector3

---@class Vector2
---@field x number
---@field y number
---@field clone fun():Vector2
---@field tuple fun():number, number
---@field info fun(decimals?:integer):string
---@field equals fun(other:Vector2):boolean
---@field set fun(arg:string, val:number):Vector2
---@field distance fun(other:Vector2):number
---@field normalize fun():Vector2
Vector2 = {}
Vector2.__index = Vector2

---@param x? number
---@param y? number
---@return Vector2
function Vector2.new(x, y)
    local self = setmetatable({}, Vector2)
    self.x = x or 0
    self.y = y or 0

    ---@return Vector2
    function self.clone()
        return Vector2.new(self.x, self.y)
    end

    ---@return number, number
    function self.tuple()
        return self.x, self.y
    end

    function self.info(decimals)
        decimals = decimals and decimals or -1
        local decText = decimals >= 0 and ("%." .. decimals .. "f") or "%f"
        return string.format("{x=" .. decText .. ", y=" .. decText .. "}", self.x, self.y)
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
        return math.sqrt((self.x - other.x)^2 + (self.y - other.y)^2)
    end

    function self.normalize()
        local length = math.sqrt(self.x^2 + self.y^2)
        return Vector2.new(self.x / length, self.y / length)
    end
    
    return self
end

-- override == operator
function Vector2.__eq(a, b)
    if getmetatable(a) ~= Vector2 or getmetatable(b) ~= Vector2 then
        return false
    end
    return a.x == b.x and a.y == b.y
end

function Vector2.__add(a, b)
    return Vector2.new(a.x + b.x, a.y + b.y)
end

function Vector2.__sub(a, b)
    return Vector2.new(a.x - b.x, a.y - b.y)
end

-- Vector2-number
function Vector2.__mul(a, b)
    return Vector2.new(a.x * b, a.y * b)
end