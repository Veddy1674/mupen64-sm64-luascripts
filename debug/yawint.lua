-- A debug lua file

local mario = require("lua.mario.Mario")
local action = require("lua.mario.Actions")
local om = require("lua.object.ObjectManager")
local dist = require("lua.math.Distance")
require("lua.misc.AJoypad")
require("lua.misc.Time")

local inputs = {}

function update()
	inputs = joypad.get()
	
	-- ground pound "recover" air dive
	if (action.get() == action.groundpounding) and (mario.speed.y == -50) then -- when mario speed y is -50 mario is stuck in air
		if inputs.A and inputs.B then
			mario.rotationyaw.facing = mario.rotationyaw.intended
			
			action.set(action.airdive)
			mario.speed.h = (inputs.X == 0 and inputs.Y == 0) and 10 or 35
			mario.speed.y = 45
		end
		
		return
	end
	
	-- backflip after ground pound
	if (action.get() == action.groundpoundland) and (mario.rotationyaw.floor == 0) then
		if inputs.A then
			action.set(action.backflip)
			mario.speed.y = 50
			mario.speed.h = 0
			
			wait(function()
				if inputs.A then
					mario.speed.y = 60
				end
			end, 8) -- is A is pressed for 9 frames then the jump will be higher
		end
		
		return
	end
	
	if (action.get() == action.airkick) then
		if inputs.Z and inputs.B then
			action.set(action.groundpounding)
			mario.speed.y = 20
			mario.speed.h = 0
		end
		
		return
	end
	
	-- if (action.get() == action.sliding) or (action.get() == action.grounddive) then
		-- if inputs.B then
			-- if (action.get() == action.grounddive) then
				-- mario.speed.h = 0
				-- mario.speed.y = 0
				-- action.set(action.stopsliding)
			-- else
				-- mario.speed.h = mario.speed.h - 10
				-- action.set(action.backwardrollout)
			-- end
		-- end
		
		-- return
	-- end
	
	-- print(mario.triangles().floor.distMario())
	-- if (action.get() == action.slidekick) and (mario.triangles().floor.distMario() == 0) then
		-- if inputs.B and inputs.A then
			-- mario.speed.h = mario.speed.h + 35
			-- mario.speed.y = 35
			-- action.set(action.backflip)
		-- end
		
		-- return
	-- end
	
	if (action.get() == action.releasingbowser) then
		
		if inputs.Z then -- more force
			local bowser = nil
			for _, o in pairs(om.getObjects()) do
				if o.is("Bowser") then
					bowser = o
					if dist.marioTo(bowser) > 350 then return end -- to avoid late Z presses when bowser is already floating
					break
				end
			end
			
			if bowser then
				action.set(action.standing)
				
				bowser.speed.y = bowser.speed.y + 20
				bowser.speed.h = bowser.speed.h + 45
			end
		end
		return
	end
	
	if (action.get() == action.softbonk) then
		if inputs.Z then
			action.set(action.groundpounding)
		end
		return
	end
end

emu.update(update)