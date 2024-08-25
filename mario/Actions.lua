-- Actions.lua
local mario = require("mario.Mario")

local module = {}

-- Actions
module.standing = 0x0C400201
module.walking = 0x04000440
module.turningaround = 0x00000443
module.airhittingwall = 0x000008A7 -- before wall kick (press A when this action for first-frame wallkick)
module.longjump = 0x03000888
module.longjumpland = 0x00000479
module.backflip = 0x01000883
module.twirling = 0x108008A4
module.punching = 0x00800457
module.groundpounding = 0x008008A9
module.groundpoundland = 0x0080023C

local ref_action = 0xC + mario.base

-- Functions
function module.get()
	return memory.readdword(ref_action)
end

function module.set(action)
	return memory.writedword(ref_action, action)
end

return module
