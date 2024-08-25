-- A library 'extension' (compiled with require(path)), not a module

local self = _G.joypad

-- range 100%
self.left = -127
self.right = 126
self.down = -128
selfup = 127

self.setOppositeDirection = function()
	local inputs = self.get()
	self.set({X = -inputs.X, Y = -inputs.Y})
end