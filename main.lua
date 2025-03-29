-- Main.lua

local actions = require("lua.mario.Actions")
local mario = require("lua.mario.Mario")

local function start()
	print("Check out the \"debug\" folder for sample scripts.")
end

local function update()
	-- random example:
	
	if (actions.get() == actions.jump) then
		mario.pos.y = mario.pos.y + 400
		actions.set(actions.groundpounding)
	end
end

start()

emu.update(function()
    update()
	--print("one frame has passed. (about 1/30 second)")
end)
