# Super Mario 64 LUA SCRIPTS for `Mupen 64 1.0.10 & 1.1.8-2`
A framework built in LUA for simple memory reading & writing.

EVERY script must be ran through Mupen64's "Lua Scripts" window.
`./tastools/` contains some random scripts for testing and playing around
`./debug/` contains some random scripts for debugging
All the other folders are part of the framework, meaning you shouldn't touch them unless you know what you're doing.

To start, you can edit `main.lua`, it is HIGHLY RECOMMENDED to use an IDE like Visual Studio Code or such.
New updated scripts (just a few sadly) now contain annotations for easy auto-completion.

`doc.txt` contains some useful info about *Mupen's lua global variables* for further debugging, as apparently there isn't any documentation on it.

`./tasbots/...` here you can see a simple example of AI (classic RL with states)
(little note: I changed something in the ai script and cannot find out what, so right now it doesn't work, if you want to fix it yourself, it's probably something about formulas)
The way the script works (check main.lua) is that a pre-determined object (in my case 43, a coin) is chosen and the AI must learn to collect it.
