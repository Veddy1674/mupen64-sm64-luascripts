-- A debug lua file
local mario = require("mario.Mario")
local actions = require("mario.Actions")

function jump2()
	actions.set(actions.jump2)
	mario.speed.y = 48
	
	print("executed")
end

function skick()
	actions.set(actions.slidekick)
	mario.speed.h = 32.15
	mario.speed.z = 20.0
	mario.speed.y = 10
	mario.speed.x = 25.0
	
	print("executed")
end

local testkeyboard = false
function start()
	print("----------------------")
	print("Press " .. (testkeyboard and "Z" or "dpadUP") .. " to slide kick")
	print("Press " .. (testkeyboard and "X" or "dpadDOWN") .. " to 2nd jump")
end

function update()
	if testkeyboard then
		local i = io.read()
		if i == "Z" then
			skick()
		elseif i == "X" then
			jump2()
		end
	else
		if joypad.get().up then
			skick()
		elseif joypad.get().down then
			jump2()
		end
	end
end

start()

emu.atinput(update)
