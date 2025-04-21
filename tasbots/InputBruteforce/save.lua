-- save.lua

require("lua.tasbots.InputBruteforce.shared")
savestate.savefile(savestateFile)
printf("Saved in \"%s\".", savestateFile)