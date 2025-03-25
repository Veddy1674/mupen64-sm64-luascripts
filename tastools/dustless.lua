-- A tas tool lua file, only-reads memory

local actions = require("lua.mario.Actions")

-- desc: Automatically dive-recovers after touching ground while diving

function start()
	print("desc: Automatically dive-recovers after touching ground while diving")
	print("Keep L pressed after diving to ignore the auto recover")
end

function update()
	if (actions.get() == actions.grounddive) and not (joypad.get().L) then
		joypad.set({A = true}) -- there is no reason to press A the frame before the ground dive action, but anyway it would fail
	end
end

start()

emu.atinput(update)