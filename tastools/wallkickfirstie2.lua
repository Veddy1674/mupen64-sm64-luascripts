-- A tas tool lua file, only-reads memory

local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")
require("lua.misc.AJoypad")
require("lua.misc.Time")

-- desc: Tells you when to press A for a nframes-frame wall jump

local frame = 1 -- hits N frame instead of default first-frame, this is useful to easily climb a wall, for example owlless...
	
function start()
	-- clamping
	-- frame = frame > 5 and 5 or frame
	-- frame = frame < 1 and 1 or frame
end

local bad, success = "Failed wall-jump :c", "Press A and move to the opposite direction"

local db = false -- starts exactly when mario hits the wall and stop when it got executed
function update()
	
	-- TODO: make sure 'speed to perform a wall jump' is actually 16 in sm64 source code, too lazy to do it rn
	if mario.speed.h >= 16 and actions.get() == actions.airhittingwall and not db then
		db = true
		
		if joypad.get().A then
			if frame == 1 then
				print(bad)
				db = false
			else
				print("Release A, frame advance")
				wait(function()
					print(success) -- todo: tell direction yaw and y and x input to reach it..
					db = false
				end, frame - 1)
			end
			return
		end
		
		if frame == 1 then
			print(success)
			db = false
			return
		end
		wait(function()
			print(success) -- todo: tell direction yaw and y and x input to reach it..
			db = false
		end, frame - 1)
	end
end

start()

emu.atinput(update)