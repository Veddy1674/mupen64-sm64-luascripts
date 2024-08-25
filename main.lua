-- Main.lua

local actions = require("lua.mario.Actions")
local mario = require("lua.mario.Mario")
local water = require("lua.water.Water")
local marioutils = require("lua.mario.MarioUtils")
local objectmanager = require("lua.object.ObjectManager")
local graphics = require("lua.object.Graphics")
local distance = require("lua.math.Distance")

function start()
	print("Write some code.. Try checking out the \"debug\" folder.")
end

function update()
	-- random example untestedbecauseimlazy code:
	
	--if (actions.get() == actions.jump) then
		--mario.speed.y = mario.speed.y + 111
		--actions.set(actions.groundpounding)
	--end
end

start()

emu.atinput(function()
    update()
	--print("one frame has passed. (about 1/30 second)")
end)
