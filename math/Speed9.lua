-- Speed9.lua: Used in mario

---@class Speed9
---@field x number
---@field y number
---@field z number
---@field h number
---@field defacto number
---@field sideways number
---@field xSliding number
---@field zSliding number
---@field hSliding number
---@field clone fun():Speed9
---@field tuple fun():number, number, number, number, number, number, number, number, number
---@field info fun(decimals?:integer):string
---@field equals fun(other:Speed9):boolean
---@field set fun(arg:string, val:number):Speed9
Speed9 = {}
Speed9.__index = Speed9

---@param x? number
---@param y? number
---@param z? number
---@param h? number
---@param defacto? number
---@param sideways? number
---@param xSliding? number
---@param zSliding? number
---@param hSliding? number
---@return Speed9
function Speed9.new(x, y, z, h, defacto, sideways, xSliding, zSliding, hSliding)
    local self = setmetatable({}, Speed9)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    self.h = h or 0
    self.defacto = defacto or 0
    self.sideways = sideways or 0
    self.xSliding = xSliding or 0
    self.zSliding = zSliding or 0
    self.hSliding = hSliding or 0

    ---@return Speed9
    function self.clone()
        return Speed9.new(self.x, self.y, self.z, self.h, self.defacto, self.sideways, self.xSliding, self.zSliding, self.hSliding)
    end

    ---@return number, number, number, number, number, number, number, number, number
    function self.tuple()
        return self.x, self.y, self.z, self.h, self.defacto, self.sideways, self.xSliding, self.zSliding, self.hSliding
    end

    function self.info(decimals)
        decimals = decimals and decimals or -1
        local decText = decimals >= 0 and ("%." .. decimals .. "f") or "%f"
        return string.format("{x=" .. decText .. ", y=" .. decText .. ", z=" .. decText .. ", h=" .. decText ..
            ", defacto=" .. decText .. ", sideways=" .. decText ..
            ", xSliding=" .. decText .. ", zSliding=" .. decText .. ", hSliding=" .. decText .. "}",
            self.x, self.y, self.z, self.h, self.defacto, self.sideways, self.xSliding, self.zSliding, self.hSliding)
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
function Speed9.__eq(a, b)
    if getmetatable(a) ~= Speed9 or getmetatable(b) ~= Speed9 then
        return false
    end
    return a.x == b.x and a.y == b.y and a.z == b.z
        and a.h == b.h and a.defacto == b.defacto and a.sideways == b.sideways
        and a.xSliding == b.xSliding and a.zSliding == b.zSliding and a.hSliding == b.hSliding
end

function Speed9.__add(a, b)
    return Speed9.new(a.x + b.x, a.y + b.y, a.z + b.z, a.h + b.h, a.defacto + b.defacto, a.sideways + b.sideways,
        a.xSliding + b.xSliding, a.zSliding + b.zSliding, a.hSliding + b.hSliding)
end

function Speed9.__sub(a, b)
    return Speed9.new(a.x - b.x, a.y - b.y, a.z - b.z, a.h - b.h, a.defacto - b.defacto, a.sideways - b.sideways,
        a.xSliding - b.xSliding, a.zSliding - b.zSliding, a.hSliding - b.hSliding)
end