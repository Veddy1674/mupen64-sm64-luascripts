-- save.lua

require("lua.misc.Utils")
local camera = require("lua.mario.Camera")

emu.update(function() camera.mode(0x0) end)
local st = "lua/tasbots/DQN/recorder/getstar.st1"
savestate.savefile(st)
printf("Saved in \"%s\".", st)