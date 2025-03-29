-- ObjectManager.lua

-- objects with "memory order" in STROOP can be obtained by doing:
-- first loaded object address + 0x260 = next object address

local object = require("lua.object.Object")
local olist = require("lua.object.ObjectList")
local distance = require("lua.math.Distance")

local om = {}

local startAddress = 0x8033D488 -- first object

---@return Object[]
function om.getObjects(order)
    local objects = {}

	-- max 240 objects can be loaded
    for slotIndex = 1, 240 do
 		-- memory processing order
        table.insert(objects, object.new(startAddress, slotIndex))
    end

	if order ~= nil and order ~= "memory" then
		om.reorderObjects(objects, order)
	end
	
	-- read-only
	objects.order = order
	return objects
end

function om.reorderObjects(objectList, order)
	if order == "memory" then
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

function om.reviveObject(o)
	o.setActive(true)
end

function om.spawnObject(o)
	local obj = om.findEmptyCell()
	print(obj.slotIndex)
	obj.clear()

	obj.bhvscript(o.bhvscript())
	obj.graphics(o.graphics())
	obj.model(o.model())

	obj.pos(o.pos())

	om.reviveObject(o)

	obj.visible(true)
	obj.active(true)

	return obj
end

function om.duplicate(o)
	return om.spawnObject(o)
end

---@param o Object
---@param o2 Object
function om.copy(o2, o)
	o2.bhvscript(o.bhvscript())
	o2.graphics(o.graphics())
	o2.model(o.model())
	o2.pos(o.pos())
	o2.visible(o.visible())
	o2.active(o.active())
	return o2
end

return om