-- ObjectManager.lua

-- memory order:
-- first loaded object address + 0x260 = next object address

local json = require("lua.lib.json")
local object = require("lua.object.Object")

startAddress = 0x8033D488 -- first object
importantAddressOffsets = {
	0x08, -- Next Object,
	0x04, -- Previous Object,
	0x60, -- Next Processed Object Address
	0x64, -- Previous Processed Object Address
	0x68, -- Parent Object
}

---@class ObjectManager
---@field getObjects fun(order?:string):Object[]
---@field reorderObjects fun(objectList:Object[], order:"Memory"|"DistToMario"):Object[]
---@field firstEmptyCell fun():Object
---@field firstUnloadedCell fun():Object
---@field copyInfo fun(obj:Object, obj2:Object):Object
---@field duplicateObject fun(obj:Object, replaceSlot?:integer):Object
---@field spawnObject fun(commonName:string,pos?:Vector3,speed?:Speed4):Object
local om = {}

---@param order "Memory"|"DistToMario"
---@return Object[]
function om.getObjects(order)
    local objects = {}

	-- max 240 objects can be loaded
    for slotIndex = 1, maxObjectSlots do
 		-- memory processing order
		local address = startAddress + (slotIndex - 1) * 0x260
        table.insert(objects, object.new(address, slotIndex))
    end

	if order ~= nil and order ~= "Memory" then
		om.reorderObjects(objects, order)
	end
	
	-- read-only
	objects.order = order
	return objects
end

-- Optimized version to get a specific object at a specific slotIndex without creating 260 objects with #getObjects()[...]
---@param slotIndex integer
---@return Object
function om.getObject(slotIndex)
	return object.new(startAddress + (slotIndex - 1) * 0x260, slotIndex)
end

-- RETURNS new sorted list, does not modify objectList param
---@param objectList? Object[]
---@param order "Memory"|"DistToMario"
function om.reorderObjects(objectList, order)
	objectList = objectList or om.getObjects()

	if order == "Memory" then
		return om.getObjects()

	elseif order == "DistToMario" then

		---@type Object|nil
		local marioObj = table.compare(objectList, function(o) return o.isA("Mario") end)
		if not marioObj then emu.stop("ObjectManager.lua: marioObj not found in objectList") end

        table.sort(objectList, function(o1, o2)
			---@cast marioObj Object
            local dist1 = o1.distanceFrom(marioObj)
            local dist2 = o2.distanceFrom(marioObj)
            return dist1 < dist2
        end)
		return objectList
    end
	---@type Object[]
	return nil
end

-- returns first empty object
function om.firstEmptyCell()
	for _, obj in pairs(om.getObjects()) do
		if obj.slotIndex <= safeSlotsLimit and obj.isEmpty() then
			return obj
		end
	end
	emu.stop("No empty slots " .. "(" .. safeSlotsLimit .. "/" .. maxObjectSlots .. " limited)")
	---@type Object
	return nil
end

-- returns first unloaded object
function om.firstUnloadedCell()
	for _, obj in pairs(om.getObjects()) do
		if obj.slotIndex <= safeSlotsLimit and not obj.isLoaded() then
			return obj
		end
	end
	emu.stop("No empty slots " .. "(" .. safeSlotsLimit .. "/" .. maxObjectSlots .. " limited)")
	---@type Object
	return nil
end

function om.copyInfo(obj, obj2)
	obj2.clear()

	-- every object stores 0x260 bytes
	for offset = 0, 0x260-0x4, 0x4 do
		if not table.any(importantAddressOffsets, function(o) return o == offset end) then
			local value = memory.access(obj.base + offset, UINT)
			memory.access(obj2.base + offset, UINT, value)
		end
	end

	obj2.parent(obj2)

	return obj2
end

function om.duplicateObject(obj, replaceSlot)
	local copied = replaceSlot and om.getObjects()[replaceSlot] or om.firstUnloadedCell()

	---@cast copied Object
	copied = om.copyInfo(obj, copied)
	copied.revive()

	return copied
end

---@param commonName "coin"|"toad"
---@param pos? Vector3
---@param speed? Speed4
function om.spawnObject(commonName, pos, speed)
	local saveFile = "lua/dev/objCommonValues/" .. commonName .. ".json"

	local file = io.open(saveFile, "r")
	if not file then emu.stop("file " .. saveFile .. " not found") end

	---@cast file file*
	local data = json.decode(file:read("*a"))
	file:close()

	local newObj = om.firstUnloadedCell()
	newObj.clear()

	for offset = 0, 0x260-0x4, 0x4 do
		if not table.any(importantAddressOffsets, function(o) return o == offset end) then
			local value = data[tostring(offset)]
			memory.access(newObj.base + offset, UINT, value)
		end
	end

	newObj.parent(newObj)

	newObj.pos(pos or Vector3.new())
    newObj.speed(speed or Speed4.new())

	newObj.revive()
	return newObj
end

return om