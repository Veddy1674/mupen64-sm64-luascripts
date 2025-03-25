-- A debug lua file

local objectmanager = require("lua.object.ObjectManager")

function start()
	for _, object in pairs(objectmanager.getObjects("DistToMario")) do
		print(tostring(object.isMario()) .. ", slot " .. object.slotIndex)
	end -- Works as excepted, info where obj.isMario is defined in Object.lua
end

start()