-- ObjectManager.lua

-- objects with "memory order" in STROOP can be obtained by doing:
-- first loaded object address + 0x260 = next object address

local object = require("lua.object.Object")
local olist = require("lua.object.ObjectList")
local distance = require("lua.math.Distance")

local om = {}

-- objectsOrder enum has been removed

--local previousObjects = {} (TODO line 30)

function om.getObjects(order)
	local baseAddress = 0x8033D488 -- always the same
    local objects = {}

	-- max 240 objects can be loaded
    for slotIndex = 0, 240 - 1 do -- must start from zero, the real slotIndex should be +1
        local address = baseAddress + (slotIndex * 0x260) -- memory processing order
        table.insert(objects, object.new(address, slotIndex + 1))
    end

	if order ~= nil and order ~= "Memory" then
		om.reorderObjects(objects, order)
	end

	--objects.order = function() return order end
	objects.order = order --! function is printed in a foreach loop, properties not, so please DO NOT modify this property in a script
    ---@type Object[]
	return objects
end

function om.reorderObjects(objectList, order)
	if order == "Memory" then
		return om.getObjects()

	elseif order == "DistToMario" then

        table.sort(objectList, function(o1, o2)
            local dist1 = distance.marioTo(o1)
            local dist2 = distance.marioTo(o2)
            return dist1 < dist2
        end)
    end
end

function om.findEmptyCell() -- returns first empty object
	for _, obj in pairs(om.getObjects()) do
		if obj.isEmpty() then
			return obj
		end
	end
end

function om.spawnObject(name, pos, speed)
	local object = om.findEmptyCell()
	object.clear()

	for n, obj in pairs(olist) do
		if n == name then
			object.bhvscript(obj.bhvscript)
			object.graphics(obj.graphics)
			object.model(obj.model)
			for name, customProperty in pairs(obj.other) do
				--object[name] = property.new(object.base, customProperty.offset, customProperty.vartype)
				object[name](customProperty.default)
			end
			break
		end
	end

	if pos then
		object.pos.x = pos.x
		object.pos.y = pos.y
		object.pos.z = pos.z
	end
	if speed then
		object.speed.h = speed.h
		object.speed.x = speed.x
		object.speed.y = speed.y
		object.speed.z = speed.z
	end

	object.visible(true)
	object.active(true)

	return object
end

function om.duplicate(slotIndex)
	local objectToDuplicate = om.getObjects()[slotIndex]

	local pos = {
		x = objectToDuplicate.pos.x,
		y = objectToDuplicate.pos.y,
		z = objectToDuplicate.pos.z
	}
	local objectDuplicated = om.spawnObject(objectToDuplicate.name(), pos)

	return objectDuplicated
end

return om