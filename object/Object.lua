-- Object.lua

local olist = require("lua.object.ObjectList")
require("misc.Utils")

maxObjectSlots = 240
safeSlotsLimit = maxObjectSlots - 25

local Object = {}
Object.__index = Object

function Object.new(address, slotIndex)

    ---@class Object
    ---@field base integer
    ---@field slotIndex integer
    ---@field pos fun(v?:Vector3):Vector3
    ---@field speed fun(v?:Speed4):Speed4
    ---@field hitbox fun(v?:Hitbox):Hitbox
    ---@field graphics fun(v?:integer):integer -- todo: change type
    ---@field model fun(v?:integer):integer -- todo: change type
    ---@field bhvscript fun(v?:integer):integer -- todo: change type
    ---@field overlapsWith fun(obj2:Object):boolean
    ---@field distanceFrom fun(obj2:Object):number
    ---@field distanceXYZFrom fun(obj2:Object):Vector3
    ---@field distanceXZFrom fun(obj2:Object):Vector3
    ---@field equals fun(other:Object):boolean
    ---@field name fun():string
    ---@field group fun():string
    ---@field isA fun(other:string):boolean
    ---@field isGroupOf fun(other:string):boolean
    ---@field facecamera fun(v?:boolean):boolean
    ---@field visible fun(v?:boolean):boolean
    ---@field active fun(v?:boolean):boolean
    ---@field load fun()
    ---@field revive fun()
    ---@field parent fun(o:Object):number
    ---@field unload fun()
    ---@field isLoaded fun():boolean
    ---@field clear fun()
    ---@field isEmpty fun():boolean
    ---@field getGroupAddress fun():number
    local obj = setmetatable({}, Object)
    obj.slotIndex = slotIndex
    obj.base = address
    -- tostring override of base
    obj.__tostring = function() return hex(obj.base) end

    ---@param v? Vector3
    ---@return Vector3
    obj.pos = function(v)
        local x = memory.access(obj.base + 0xA0, FLOAT, v and v.x or nil)
        local y = memory.access(obj.base + 0xA4, FLOAT, v and v.y or nil)
        local z = memory.access(obj.base + 0xA8, FLOAT, v and v.z or nil)
        return Vector3.new(x, y, z)
    end
    ---@param v? Speed4
    ---@return Speed4
    obj.speed = function(v)
        local x = memory.access(obj.base + 0xAC, FLOAT, v and v.x or nil)
        local y = memory.access(obj.base + 0xB0, FLOAT, v and v.y or nil)
        local z = memory.access(obj.base + 0xB4, FLOAT, v and v.z or nil)
        local h = memory.access(obj.base + 0xB8, FLOAT, v and v.h or nil)
        return Speed4.new(x, y, z, h)
    end
    obj.hitbox = function(v)
        local radius = memory.access(obj.base + 0x1F8, FLOAT, v and v.radius or nil)
        local height = memory.access(obj.base + 0x1FC, FLOAT, v and v.height or nil)
        local down = memory.access(obj.base + 0x208, FLOAT, v and v.down or nil)
        return Hitbox.new(radius, height, down)
    end
    obj.graphics = function(v)
        return memory.access(obj.base + 0x14, UINT, v)
    end
    obj.model = function(v)
        return memory.access(obj.base + 0x218, UINT, v)
    end
    obj.bhvscript = function(v)
        return memory.access(obj.base + 0x20C, UINT, v)
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

    -- Returns distance between obj and arg1 as a number
    ---@param o2 Object
    ---@return number
    obj.distanceFrom = function(o2)
        return obj.pos().distance(o2.pos())
    end
    -- Returns distance between obj and arg1 as a Vector3
    ---@param o2 Object
    ---@return Vector3
    obj.distanceXYZFrom = function(o2)
        return obj.pos() - o2.pos()
    end
    -- Returns distance between obj and arg1 ignoring Y axis
    ---@param o2 Object
    ---@return Vector3
    obj.distanceXZFrom = function(o2)
        local p1 = obj.pos().set("y", 0)
        local p2 = o2.pos().set("y", 0)
        return p1 - p2
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

    -- obj.facecamera = function(v) property.savebyte(obj.base, 0x3, 0x04, v) end
    -- obj.visible = function(v) property.savebyte(obj.base, 0x3, 0x10, v) end
    -- obj.active = function(v) property.savebyte(obj.base, 0x3, 0x01, v) end
    obj.load = function()
        memory.access(obj.base + 0x74, USHORT, 0x101)
    end
    obj.unload = function()
        memory.access(obj.base + 0x74, USHORT, 0x0)
    end
    obj.isLoaded = function()
        return memory.access(obj.base + 0x74, USHORT) ~= 0x0
    end
    obj.getGroupAddress = function()
        local bhvScriptStart = obj.bhvscript()
        if bhvScriptStart == 0 then
            ---@type number
            return nil
        end
    
        local firstScriptAction = memory.access(bhvScriptStart, UINT)
    
        if (firstScriptAction & 0xFF000000) ~= 0 then
            ---@type number
            return nil
        end
    
        return 0x8033CBE0 + (((firstScriptAction & 0x00FF0000) >> 16) * 0x68)
    end
    obj.revive = function()
        -- logic found in https://github.com/SM64-TAS-ABC/STROOP/blob/dev/STROOP/Utilities/ButtonUtilities.cs#L502
        -- https://github.com/SM64-TAS-ABC/STROOP/blob/dev/STROOP/Models/ObjectDataModel.cs#L86
        -- https://github.com/SM64-TAS-ABC/STROOP/blob/dev/STROOP/Structs/Configurations/ObjectSlotsConfig.cs

        local groupAddress = obj.getGroupAddress()
        if groupAddress == nil then emu.stop("Group address error") end -- unknown error
        local lastGroupObj = groupAddress

        repeat
            lastGroupObj = memory.access(lastGroupObj + 0x60, UINT)
        until memory.access(lastGroupObj + 0x60, UINT) == groupAddress

        local nextObj = memory.access(obj.base + 0x60, UINT)

        local prevObj = 0x803610F0
        for i = 1, maxObjectSlots do
            local curObj = memory.access(prevObj + 0x60, UINT)
            if curObj == obj.base then break end
            prevObj = curObj
        end

        memory.access(prevObj + 0x60, UINT, nextObj)

        local nextGroupObj = memory.access(lastGroupObj + 0x60, UINT)
        memory.access(nextGroupObj + 0x64, UINT, obj.base)
        memory.access(lastGroupObj + 0x60, UINT, obj.base)
        memory.access(obj.base + 0x64, UINT, lastGroupObj)
        memory.access(obj.base + 0x60, UINT, nextGroupObj)

        obj.load()

    end
    obj.parent = function(o)
        return memory.access(obj.base + 0x68, UINT, o == nil and nil or o.base)
    end

    -- Unactive and disable, set graphic, bhvscript, model all to 0x0
    obj.clear = function()
        -- obj.active(false)
        obj.graphics(0x0)
        obj.bhvscript(0x0)
        obj.model(0x0)
        obj.unload()
    end

    obj.isEmpty = function() return obj.bhvscript() == 0x0 end

    return obj
end

Object.__eq = function(a, b) return a.equals(b) end
Object.__tostring = function(obj) return obj.name() .. " (slot " .. obj.slotIndex .. ")" end

return Object