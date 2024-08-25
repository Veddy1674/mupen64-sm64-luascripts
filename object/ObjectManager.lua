-- ObjectManager.lua

-- discovery i made: objects memory order from STROOP can be obtained by doing:
-- first loaded object address + 0x260 = next object address

local object = require("object.Object")
local distance = require("math.Distance")

local module = {}

-- objectsOrder enum has been removed

--local previousObjects = {} (TODO line 30)

-- note: slot positions called "VS" in stroop seems to have alot of decimals, but so does mario and other entities like MIPS, toads, bowser
function module.getObjects(order)
	local baseAddress = 0x8033D488 -- always the same
    local objects = {}
	
	-- max 240 objects can be loaded
    for slotIndex = 0, 240 - 1 do -- must start from zero, the real slotIndex should be +1
        local address = baseAddress + (slotIndex * 0x260) -- memory processing order
        table.insert(objects, object.new(address, slotIndex + 1))
    end
	
	if order ~= nil and order ~= "Memory" then
		module.reorderObjects(objects, order)
	end
	
	-- TODO: - Object.lua comment
	
	--objects.order = function() return order end
	objects.order = order --! function is printed in a foreach loop, properties not, so please DO NOT modify this property in a script
    return objects
end

function module.reorderObjects(objectList, order)
	if order == "Memory" then
		return module.getObjects()
		
	elseif order == "DistToMario" then
	
        table.sort(objectList, function(o1, o2)
            local dist1 = distance.marioTo(o1)
            local dist2 = distance.marioTo(o2)
            return dist1 < dist2
        end)
    end
end

function module.findEmptyCell(list) -- returns first empty object address
	list = (list == nil or list.order ~= "Memory") and module.getObjects("Memory")
	
	-- list = all the objects in the MemoryProcessed order
	for _, obj in pairs(list) do
		if obj.nativeRoom == 0 then return obj end
	end
	-- returns last object
	return list[#list]
end

function module.spawnObject(name, overwrite, graphics, model, _pos) -- overwrite is an int, the slotIndex of the object to remove
	
	local obj = overwrite ~= nil and
		module.getObjects()[overwrite] or
		module.findEmptyCell()
	
	obj.clear() -- not all properties gets overwritten
	
	obj.active = true
	obj.graphics = graphics[1]
	obj.model = model
	-- pos is something like {x = 1, y = 2, z = 3}
	if _pos then
		obj.pos.x = _pos.x
		obj.pos.y = _pos.y
		obj.pos.z = _pos.z
	end
	
	-- forcing readonly functions
	memory.writedword(obj.base + 0x1A0, -1) -- nativeRoom
	memory.writedword(obj.base + 0x020C, graphics[3]) -- bhvscript
	-- set all other custom default properties
	if (graphics[4] ~= nil) then
		for _, p in pairs(graphics[4]) do
			local offset = p[1]
			local defaultValue = p[2]
			local typename = p[3]
			memory.access(obj.base + offset, typename, defaultValue)
		end
	end
	
	return obj
end

function module.removeObject(slotIndex)
	local obj = module.getObjects()[slotIndex]
	obj.clear()
end

return module