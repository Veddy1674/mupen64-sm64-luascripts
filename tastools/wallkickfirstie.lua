-- A tas tool lua file, only-reads memory

local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")
require("lua.misc.AJoypad")
require("lua.misc.Time")

-- desc: Pauses emulation (or automatically press A) when mario is about to wall jump to do a 'firstie'

local pause = false -- previously called "auto"
local frame = 1 -- hits N frame instead of default first-frame, this is useful to easily climb a wall, for example owlless...
local failsafe = true
local db = false
	
function start()
	-- clamping
	frame = frame > 5 and 5 or frame
	frame = frame < 1 and 1 or frame
	
	local suffix = (frame == 1) and "st" or (frame == 2) and "nd" or (frame == 3) and "rd" or "th"
	
	local desc = frame == 1 and
		"To execute first-frame walljumps, you need to release A before touching wall! (Otherwise if failsafe is active, you'll do a second-frame walljump, if isn't then your latest savestate will be loaded by default.)" or
		"To execute " .. frame .. suffix .. "-frame walljumps, you can just press A and jump towards a wall!"
	
	print("Goal: " .. frame .. suffix .. "-frame wall jump")
	if frame == 1 then print("Failsafe: " .. tostring(failsafe)) end
	print("Pause: " .. tostring(pause))
	print("Notice: " .. desc)
end

function update()
	
	-- TODO: make sure 'speed to perform a wall jump' is actually 16 in sm64 source code, too lazy to do it rn
	if mario.speed.h >= 16 and actions.get() == actions.airhittingwall then
		
		-- if you are already pressing A, there is no way to prevent the fail, I was thinking about saving state every frame but performantly that's not a good idea...
		if joypad.get().A then
			if frame == 1 then
				print("Failed wall-jump :c")
			else
				print("Success!")
			end
			if failsafe or frame ~= 1 then
				if frame == 1 then -- failsafe is on
					joypad.setOppositeDirection()
					joypad.set({A = false})
					
					wait(function() joypad.set({A = true}) end, frame)
					return
				end
				-- All this code here isn't properly working, tested: with a 5th frame walljump it jumps on 3rd frame instead...
			
				-- joypad.setOppositeDirection()
				joypad.set({A = false})
				
				for i = 1, frame do -- keep A unpressed 
					wait(function() joypad.set({A = false}) end, 1)
				end
				
				wait(function() joypad.set({A = true}) end, frame)
			elseif failsafe then
				-- load latest savestate?
			end
			return
		end
		
		print("Success!")
		
		if frame ~= 1 then
			wait(function()
				joypad.setOppositeDirection()
			end, 1)
			wait(function() -- waits "frame" frames for bonk before doing anything
				joypad.set({A = true})
			end, frame + 2)
			return
		end
		
		joypad.setOppositeDirection()
		joypad.set({A = true})
		
		if pause then
			emu.pause()
			print("Keep A pressed and frame advance for how many frames you want, then unpause (consider moving joystick too)")
		else -- auto
			wait(function() -- keeping A pressed for 1 more frame by default
				joypad.set({A = true})
			end, 1)
		end
	end
end

start()

emu.atinput(update)