-- A debug lua file

local objectmanager = require("lua.object.ObjectManager")
local distance = require("lua.math.Distance")
local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")
local um = require("lua.math.UtilsMath")

local floatIslands = {}
function getIslands(callback)
    for _, island in pairs(floatIslands) do
        callback(island)
    end
end

local touchingIslands = {} -- support to update more than one island per time

local t = 0

--local db = false
function update()
	
	if #floatIslands > 0 then
		
		-- Doesn't work properly with multiple touching islands, reason is I didn't find yet a good way to check if mario is touching something.
		getIslands(function(island)
            if distance.axisEqZero(mario, island, "y") then
				table.insert(touchingIslands, island)
			else
				table.remove(touchingIslands, island)
			end
		end)
			
		-- to set a precise decrease value.. maybe you can do this:
		-- check for how many frames does mario ground pound land animation, and decrease island pos y by units / frames...
	else
		t = t + 1
		--print("waiting for island since " .. tostring(t) .. " frames (" .. tostring(um.round(t / 30, 1)) .. "s)")
		for _, object in pairs(objectmanager.getObjects("DistToMario")) do
			
			if object.is("floating island") then
				table.insert(floatIslands, object)
				print("found island " .. #floatIslands .. " in " .. tostring(t) .. " frames (" .. tostring(um.round(t / 30, 2)) .. " seconds)")
				
				-- here you can write code like in start()
				
				getIslands(function(island)
					island.pos.y = 3584
					-- this value is only valid for the first island, there is no concrete way to AUTOMATICALlY
					-- get every island default position (imagine if a island is already outplaced and the script re-runs...)
				end)
				-- (the support for multiple island was added later on, some comments were deleted)
				
				--break
			end
		end
	end
	
	-- Works as excepted
end

-- start()

emu.atinput(update)