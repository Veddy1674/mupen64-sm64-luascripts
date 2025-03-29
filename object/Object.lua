-- Object.lua

local olist = require("lua.object.ObjectList")
local property = require("misc.Utils")

local Object = {}
Object.__index = Object

function Object.new(startAddress, slotIndex)

    ---@class Object
    local obj = setmetatable({}, Object)
    obj.slotIndex = slotIndex
    obj.base = function()
        return startAddress + ((obj.slotIndex-1) * 0x260)
    end

    ---@param v? Vector3
    ---@return Vector3
    obj.pos = function(v)
        local x = memory.access(obj.base() + 0xA0, FLOAT, v and v.x or nil)
        local y = memory.access(obj.base() + 0xA4, FLOAT, v and v.y or nil)
        local z = memory.access(obj.base() + 0xA8, FLOAT, v and v.z or nil)
        return Vector3.new(x, y, z)
    end
    ---@param v? Speed4
    ---@return Speed4
    obj.speed = function(v)
        local x = memory.access(obj.base() + 0xAC, FLOAT, v and v.x or nil)
        local y = memory.access(obj.base() + 0xB0, FLOAT, v and v.y or nil)
        local z = memory.access(obj.base() + 0xB4, FLOAT, v and v.z or nil)
        local h = memory.access(obj.base() + 0xB8, FLOAT, v and v.h or nil)
        return Speed4.new(x, y, z, h)
    end
    obj.graphics = function(v)
        return memory.access(obj.base() + 0x14, UINT, v)
    end
    obj.model = function(v)
        return memory.access(obj.base() + 0x218, UINT, v)
    end
    obj.bhvscript = function(v)
        return memory.access(obj.base() + 0x20C, UINT, v)
    end
    obj.hitbox = function(v)
        local radius = memory.access(obj.base() + 0x1F8, FLOAT, v and v.radius or nil)
        local height = memory.access(obj.base() + 0x1FC, FLOAT, v and v.height or nil)
        local down = memory.access(obj.base() + 0x208, FLOAT, v and v.down or nil)
        return Hitbox.new(radius, height, down)
    end

    ---@param obj2 Object
    obj.overlapsWith = function(obj2)
        local p1, p2 = obj.pos(), obj2.pos()
        local h1, h2 = obj.hitbox(), obj2.hitbox()

        local dxz = p1.distance(Vector3.new(p2.x, p1.y, p2.z)) -- horizontally
        local dy = math.abs(p1.y - p2.y) -- vertically

        local radiusSum = h1.radius + h2.radius
        local heightOverlap = (p1.y - h1.down < p2.y + h2.height - h2.down) and
                            (p1.y + h1.height - h1.down > p2.y - h2.down)

        return dxz < radiusSum and heightOverlap
    end

    ---@param o2 Object
    obj.distanceFrom = function(o2)
        return obj.pos().distance(o2.pos())
    end

    -- Compares object by behavior script
    obj.equals = function(o2) return obj.bhvscript() == o2.bhvscript() end

    obj.name = function()
        for name, objInfo in pairs(olist) do
            if obj.bhvscript() == objInfo.bhvscript then return name end
        end
        return "Unknown"
    end

    -- Returns a common name for the object (ObjectList.lua)
    obj.group = function()
        for name, objInfo in pairs(olist) do
            if obj.isA(name) then return objInfo.group end
        end
        return "None"
    end

    -- Compares objects by name
    obj.isA = function(name) return string.lower(obj.name()) == string.lower(name) end

    -- Compares group (equalsIgnoreCase)
    obj.isGroupOf = function(groupName) return string.lower(obj.group()) == string.lower(groupName) end

    obj.facecamera = function(v) property.savebyte(obj.base(), 0x3, 0x04, v) end
    obj.visible = function(v) property.savebyte(obj.base(), 0x3, 0x10, v) end
    obj.active = function(v) property.savebyte(obj.base(), 0x3, 0x01, v) end
    obj.setActive = function(active)
        return memory.access(obj.base() + 0x74, USHORT, active and 0x0101 or 0)
    end

    obj.clear = function()
        obj.active(false)
        obj.graphics(0x0)
        obj.bhvscript(0x0)
    end

    obj.isEmpty = function() return obj.bhvscript() == 0x0 end

    return obj
end

Object.__eq = function(a, b) return a.equals(b) end

return Object