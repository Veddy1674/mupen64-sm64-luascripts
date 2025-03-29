-- A debug lua file

local objectmanager = require("lua.object.ObjectManager")
local distance = require("lua.math.Distance")
local um = require("lua.math.UtilsMath")

local coinBlock = nil
function start()
	for _, object in pairs(objectmanager.getObjects()) do
		if object.is("blue coin block") then
			print(object.bhvscript())
		end
	end
end

function update()
	
end

start()

emu.update(update)