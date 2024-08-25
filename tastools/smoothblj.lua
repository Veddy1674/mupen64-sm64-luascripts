-- A tas tool lua file, WRITES memory

local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")
require("lua.misc.AJoypad")
require("lua.misc.Time")

function start()
	print("WARN: this lua script WRITES memory, meaning it's not legit to use this in a TAS or any speedrun!")
end

function update()
    if (actions.get() == actions.longjump) then -- nested ifs to make it more readable
		if mario.triangles().floor.distMario() <= 10.0 then
			mario.speed.h = mario.speed.h - 10
			mario.speed.y = mario.speed.y - 20
		end
	end
end

start()

emu.atinput(update)