-- A tas tool lua file, only-reads memory

local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")
local um = require("lua.math.UtilsMath")
require("lua.misc.AJoypad")
require("lua.misc.Time")

-- desc: Hold down a direction and wait until mario reaches the target speed.
local targetspeed = 16
local times = -1 -- type "-1" for unlimited
local force = false

--! supports angles, meaning I added an action condition (is turning around? 0x00000443), if isn't satisfied emulation won't stop
function start()
	if mario.speed.h >= targetspeed and not force then
		print("It is reccomended to not start the script if target speed condition (mario h speed >= " .. targetspeed .. ") already is satisfied.")
		_G.stop()
		return
	end
	print("Waiting for Mario to reach target speed " .. targetspeed .. "...")
end

local db = false
-- local waitingForA = false
local t = 0

function update()
    if mario.speed.h >= targetspeed and actions.get() == actions.walking then
        if not db then
            db = true
            print("Target speed reached, mario h speed: " .. um.round(mario.speed.h, 1) .. " / " .. um.round(targetspeed, 1))
			
			-- opposite direction for two frames, then stops emulation and waits for A button:
			
			local savePosition = joypad.setOppositeDirection() -- frame 1
			
			wait(function()
				-- TODO: add better angle support, to avoid useless frame 1 (rn it is required to detect the action, no way to predict it yet, maybe rewind? or savestates?)
				if actions.get() ~= actions.turningaround then print("Wrong angle detected.") return end
			
				joypad.setOppositeDirection() -- frame 2
				
				emu.pause()
				-- waitingForA = true
					
				print("Press A button, then unpause. (consider moving joystick too)")
				
				if times ~= -1 then
					t = t + 1
					if t > times then
						_G.stop()
					end
				end
				
				
			end, 1)
        end
    else
        db = false
    end
end

-- function waitForA()
	-- if waitingForA then
		
		-- if (joypad.get().A) then
			
			-- waitingForA = false
			-- emu.pause(0)
			
			-- t = t + 1
			-- if t > times then
				-- _G.stop()
			-- end
		-- end
	-- end
-- end

_G.start(start)

emu.atinput(update)

-- emu.atvi(waitForA) -- runs while emulation is stopped