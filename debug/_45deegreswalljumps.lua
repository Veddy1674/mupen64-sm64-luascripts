-- A debug lua file

local mario = require("lua.mario.Mario")
local actions = require("lua.mario.Actions")

local touchingWall = false

function update()
	touchingWall = (mario.triangles().wall.base() ~= 0x0)
	
	if mario.triangles().floor.distMario() >= 170 and touchingWall and mario.speed.h > 16 then
		actions.set(actions.airhittingwall)
	end
end

emu.atinput(update)