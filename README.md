## Note: I consider this project *old* and not quite useful for anything, I could say it was an experiment of the old me, not something long-term. This project, or atleast, this branch, will be left as it is. Just as a memory for myself, as I made this when I was roughly 15 to 16 years old, I believe. Cheers everyone!

# Super Mario 64 LUA SCRIPTS for `Mupen 64 1.0.10 & 1.1.8-2`
**Tested in versions: 1.0.10, 1.1.8.2, 1.1.9-8, previous versions might be unstable**

A little framework built in LUA through *Mupen64's lua scripts support*, used for memory reading & writing.

EVERY script must be ran through Mupen64's "Lua Script" window.
`./tastools/` contains some random scripts for testing and playing around
`./debug/` contains some random scripts for debugging (ignore)
All the other folders are part of the framework, meaning you shouldn't touch them unless you know what you're doing.

To start, you can edit `main.lua`, it is HIGHLY RECOMMENDED to use an IDE like Visual Studio Code or such.
New updated scripts (just a few sadly) now contain annotations for auto-completion.

`doc.txt` contains some useful info about *Mupen64's global variables* (_G.memory, for example), as there isn't much documentation on it.

`./tasbots/...` here you can see examples of AIs, doing my best to simplify it and make it more generalized.

Notes: do not run scripts inside hidden folders, as the emulator may crash
