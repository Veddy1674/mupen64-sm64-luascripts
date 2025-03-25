-- Object.lua

local olist = require("lua.object.ObjectList")
local property = require("lua.misc.Property")

local Object = {}
Object.__index = Object

function Object.new(address, slotIndex)

    ---@class Object
    local obj = setmetatable({}, Object)
    obj.base = address -- readonly
    obj.slotIndex = slotIndex -- readonly

    -- Properties
    obj.pos = property.new(address, { x = 0xA0, y = 0xA4, z = 0xA8 }, types.FLOAT)
    obj.speed = property.new(address, { h = 0xB8, x = 0xAC, y = 0xB0, z = 0xB4 }, types.FLOAT)
    obj.graphics = property.new(address, 0x14, types.UINT)
    obj.model = property.new(address, 0x218, types.UINT)
    obj.bhvscript = property.new(address, 0x20C, types.UINT)

    -- Methods
    obj.equals = function(o2) return obj.bhvscript() == o2.bhvscript() end

    obj.name = function()
        for name, objInfo in pairs(olist) do
            if obj.bhvscript() == objInfo.bhvscript then return name end
        end
        return "Unknown"
    end

    obj.group = function()
        for name, objInfo in pairs(olist) do
            if obj.is(name) then return objInfo.group end
        end
        return "None"
    end

    obj.is = function(name) return string.lower(obj.name()) == string.lower(name) end
    obj.isGroupOf = function(groupName) return string.lower(obj.group()) == string.lower(groupName) end

    obj.facecamera = function(v) property.savebyte(address, 0x3, 0x04, v) end
    obj.visible = function(v) property.savebyte(address, 0x3, 0x10, v) end
    obj.active = function(v) property.savebyte(address, 0x3, 0x01, v) end

    obj.clear = function()
        obj.active(false)
        obj.graphics(0x0)
        obj.bhvscript(0x0)
    end

    obj.isEmpty = function() return obj.bhvscript() == 0x0 end

    return obj
end

return Object