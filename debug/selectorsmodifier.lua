-- A debug lua file

local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

local isInStarSelector = false
local stars = {}

function start()
	-- local coin = om.spawnObject("Coin", {
		-- x = mario.pos.x,
		-- y = mario.pos.y + 30,
		-- z = mario.pos.z
	-- })
	-- print(coin.slotIndex)

	local coin = om.duplicate(18)
	coin.pos.y = coin.pos.y + 25
	coin.active(true)
	print("Cloned coin: " .. coin.slotIndex)
end

function update()

end

_G.start(start)

emu.update(update)