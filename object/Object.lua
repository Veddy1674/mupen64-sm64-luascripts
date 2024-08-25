-- Object.lua
local marioutils = require("mario.MarioUtils")
local graphicslist = require("object.Graphics")
local mario = require("mario.Mario")
local property = require("misc.Property")

local module = {}
module.__index = module

function module.new(address, slotIndex)
    local obj = setmetatable({}, module)
	
	obj.base = address -- readonly
	obj.slotIndex = slotIndex -- readonly
	
	-- create_property_table automatically handles the getters/setters functions
    obj.pos = property.new(address, {
		x = 0xA0,
		y = 0xA4,
		z = 0xA8
	}, "float")
    obj.speed = property.new(address, {
		h = 0xB8, -- main speed
		x = 0xAC,
		y = 0xB0,
		z = 0xB4 -- todo: add defacto, sideways, sliding speeds
	}, "float")
	
	obj.graphics = property.new(address, 0x14, "uint")
    obj.model = property.new(address, 0x218, "uint")
	obj.bhvscript = property.new(address, 0x020C, "uint")
	
	-- unsafe
	obj.isMario = function()
		return obj.graphics == graphicslist.mario and obj.pos == mario.pos
	end
	
	obj.name = function()
		return getObjectName(obj) -- depends on graphics
	end
	
	obj.is = function(name) -- depends on graphics
		return string.lower(name) == string.lower(obj.name) -- lower thingy is used to ignore case
	end
	
	-- depends on graphics
	obj.facecamera = function(v)
		marioutils.byte_property(address, 0x3, 0x04, v)
	end
	
	obj.visible = function(v)
		marioutils.byte_property(address, 0x3, 0x10, v)
	end
	
	obj.active = function(v)
		marioutils.byte_property(address, 0x3, 0x1, v)
	end
	
	obj.nativeRoom = property.new(address, 0x1A0, "int")
	
	obj.clear = function() -- AKA objectmanager.removeObject(obj)
		obj.active = false
		obj.graphics = 0x0
		-- forcing readonly functions
		memory.writedword(obj.base + 0x1A0, 0) -- nativeRoom
		memory.writedword(obj.base + 0x020C, 0x0) -- bhvscript
	end
	
    return obj
end

-- local
function getObjectName(obj)
	if obj.isMario() then return "Mario" end
	
	for _,val in pairs(graphicslist) do
        if obj.graphics == val[1] then
            return val[2]
        end
    end
	return "Unknown"
	
end

-- Only coins, red coins, blue coins, 1-ups, all trees. Activators, spawners or managers are excluded (false)
function getFacesCamera(obj)
	for _,val in pairs(graphicslist) do
        if obj.graphics() == val[1] then
            return val[3]
        end
    end
	return false
	
end

return module