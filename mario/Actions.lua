-- Actions.lua

local mario = require("lua.mario.Mario")

local t = {}

-- Actions
t.standing = 0x0C400201
t.walking = 0x04000440
t.turningaround = 0x00000443
t.slidekick = 0x018008AA
t.grounddive = 0x00880456
t.airdive = 0x0188088A
t.airkick = 0x018008AC
t.stopsliding = 0x00000386
t.hasbowser = 0x00000391
t.releasingbowser = 0x00000392
t.softbonk = 0x010208B6
t.backwardrollout = 0x010008AD
t.sliding = 0x008C0453
t.jump = 0x03000880
t.jump2 = 0x03000881
t.jump3 = 0x01000882
t.airhittingwall = 0x000008A7 -- before wall kick (press A when this action for first-frame wallkick)
t.longjump = 0x03000888
t.longjumpland = 0x00000479
t.backflip = 0x01000883
t.twirling = 0x108008A4
t.punching = 0x00800457
t.groundpounding = 0x008008A9
t.groundpoundland = 0x0080023C

local ref_action = 0xC + mario.base

-- Functions
function t.get()
	return memory.readdword(ref_action)
end

function t.set(action)
	return memory.writedword(ref_action, action)
end

return t
