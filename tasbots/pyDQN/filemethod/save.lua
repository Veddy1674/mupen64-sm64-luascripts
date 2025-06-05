-- save.lua

require("lua.misc.Utils")

local st = "lua/tasbots/pyDQN/filemethod/getstar.st1"
savestate.savefile(st)
printf("Saved in \"%s\".", st)