-- A debug lua file

local objectmanager = require("lua.object.ObjectManager")
local distance = require("lua.math.Distance")
local um = require("lua.math.UtilsMath")

function start()
	for _, object in pairs(objectmanager.getObjects("DistToMario")) do -- automatically get pos
		local dist = distance.marioTo(object)
		local t = um.approx(dist, 0.0) and " (may be Mario obj)" or ""
		print("slot " .. object.slotIndex .. ": " .. um.round(dist, 4)  .. " units from Mario" .. t)
	end -- Works as excepted
end

start()