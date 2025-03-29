-- A debug lua file

local mario = require("lua.mario.Mario")
local omanager = require("lua.object.ObjectManager")
local dist = require("math.Distance")

local range = 400
local magnetStrength = 15

function update()
	for _, obj in pairs(omanager.getObjects("DistToMario")) do
		if obj.isEmpty() then return end
		
		local distance = dist.marioTo(obj)
		
		if obj.isGroupOf("Coin") and distance <= range then
			obj.pos.x = obj.pos.x + ((mario.pos.x - obj.pos.x) / distance) * magnetStrength
			obj.pos.y = obj.pos.y + ((mario.pos.y - obj.pos.y) / distance) * magnetStrength
			obj.pos.z = obj.pos.z + ((mario.pos.z - obj.pos.z) / distance) * magnetStrength
		end
	end
end

emu.update(update)