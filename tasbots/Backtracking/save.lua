-- save.lua

require("lua.misc.Utils")

local st = "lua/tasbots/DQN/recorder/slide.st1"
savestate.savefile(st)
printf("Saved in \"%s\".", st)