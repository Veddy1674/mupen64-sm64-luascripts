-- A debug lua file

local objectmanager = require("lua.object.ObjectManager")
local graphics = require("lua.object.Graphics")
local mario = require("lua.mario.Mario")

function start()
	-- UNFINISHED! not working properly, there may be issues in property.lua because this file was made for a previous version of it

	-- local objectToSpawn = objectmanager.spawnObject("Coin", nil, graphics.coin, 0x0, {
		-- x = mario.pos.x,
		-- y = mario.pos.y + 200,
		-- z = mario.pos.z
	-- })
	
	-- testing new properties.. (unfinished)
	print(tostring(mario.pos))
	print(tostring(mario.pos.x))
	print(tostring(mario.livescount))
	
	--print(objectToSpawn.bhvscript)
	-- print("Object \"" .. objectToSpawn.name() .. "\" has been spawned, in slot " .. objectToSpawn.slotIndex)
end

start()

--emu.atinput(update)