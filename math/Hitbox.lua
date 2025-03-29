-- HitboHitbox.lua

---@class Hitbox
---@field radius number
---@field height number
---@field down number
---@field clone fun():Hitbox
---@field tuple fun():number, number, number
---@field info fun(decimals?:integer):string
---@field equals fun(other:Hitbox):boolean
---@field set fun(arg:string, val:number):Hitbox
Hitbox = {}
Hitbox.__index = Hitbox

---@param radius? number
---@param height? number
---@param down? number
---@return Hitbox
function Hitbox.new(radius, height, down)
    local self = setmetatable({}, Hitbox)
    self.radius = radius or 0
    self.height = height or 0
    self.down = down or 0

    ---@return Hitbox
    function self.clone()
        return Hitbox.new(self.radius, self.height, self.down)
    end

    ---@return number, number, number
    function self.tuple()
        return self.radius, self.height, self.down
    end

    function self.info(decimals)
        decimals = decimals and decimals or -1
        local decText = decimals >= 0 and ("%." .. decimals .. "f") or "%f"
        return string.format("{radius=" .. decText .. ", height=" .. decText .. ", down=" .. decText .. "}", self.radius, self.height, self.down)
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
function Hitbox.__eq(a, b)
    if getmetatable(a) ~= Hitbox or getmetatable(b) ~= Hitbox then
        return false
    end
    return a.radius == b.radius and a.height == b.height and a.down == b.down
end

function Hitbox.__add(a, b)
    return Hitbox.new(a.radius + b.radius, a.height + b.height, a.down + b.down)
end

function Hitbox.__sub(a, b)
    return Hitbox.new(a.radius - b.radius, a.height - b.height, a.down - b.down)
end