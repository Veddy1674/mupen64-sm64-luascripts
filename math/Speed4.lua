-- Speed4.lua: Used in objects

---@class Speed4
---@field x number
---@field y number
---@field z number
---@field h number
---@field clone fun():Speed4
---@field tuple fun():number, number, number, number
---@field info fun(decimals?:integer):string
---@field equals fun(other:Speed4):boolean
---@field set fun(arg:string, val:number):Speed4
Speed4 = {}
Speed4.__index = Speed4

---@param x? number
---@param y? number
---@param z? number
---@param h? number
---@return Speed4
function Speed4.new(x, y, z, h)
    local self = setmetatable({}, Speed4)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    self.h = h or 0

    ---@return Speed4
    function self.clone()
        return Speed4.new(self.x, self.y, self.z, self.h)
    end

    ---@return number, number, number, number
    function self.tuple()
        return self.x, self.y, self.z, self.h
    end

    function self.info(decimals)
        decimals = decimals and decimals or -1
        local decText = decimals >= 0 and ("%." .. decimals .. "f") or "%f"
        return string.format("{x=" .. decText .. ", y=" .. decText .. ", z=" .. decText .. ", h=" .. decText .. "}", self.x, self.y, self.z, self.h)
    end

    function self.equals(other)
        return self == other
    end

    function self.set(arg, val)
        local new = self.clone()
        new[arg] = val
        return new
    end
    
    return self
end

-- override == operator
function Speed4.__eq(a, b)
    if getmetatable(a) ~= Speed4 or getmetatable(b) ~= Speed4 then
        return false
    end
    return a.x == b.x and a.y == b.y and a.z == b.z and a.h == b.h
end

function Speed4.__add(a, b)
    return Speed4.new(a.x + b.x, a.y + b.y, a.z + b.z, a.h + b.h)
end

function Speed4.__sub(a, b)
    return Speed4.new(a.x - b.x, a.y - b.y, a.z - b.z, a.h - b.h)
end