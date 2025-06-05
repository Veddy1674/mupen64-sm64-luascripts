-- A debug lua file for doc.txt

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
require("lua.lib.aiutils")

local limits = wgui.info()
print(limits["width"], limits["height"])

-- emu.atUpdateScreen(function()
--     local input = input.get()
--     local mouseX, mouseY = input["xmouse"], input["ymouse"]
--     clamp(mouseX, limits["width"] / 2, limits["height"] / 2)

--     print(mouseX, mouseY)
--     -- left, top, right, bottom
--     wgui.rect(mouseX-20,mouseY-20,40,40)
-- end)