## GENERAL INFO:
true = 0x10 (equals 16 in decimal)
false = 0x0

E.G:
memory.writebyte(base + address + mask, 0x10) -- sets address value to true

prints are memory intensive, it makes the emulator drop by fps



### _G.emu functions:

ismainwindowinforeground
getversion
atinput -- loop, the most reccomended: runs every game frame, stops when emulator stops
statusbar
screenshot
debugview
getpause
speedmode -- ???
atstop
isreadonly
atstopmovie
atsavestate
atloadstate
atreset
atinterval -- loop
setgfx
atplaymovie
getsystemmetrics
getaddress
atwindowmessage
speed -- setter
atvi -- loop, reccomended
getspeed
samplecount
play_sound -- string as argument, does nothing???
inputcount
framecount
pause -- it should accept an integer paremeter (0 or 1?)
console -- makes emulator crash? use print() instead
atupdatescreen -- loop

### _G.input functions:

get -- returns { ymouse=integer, xmouse=integer, numlock=boolean }
diff -- arg1 ?? arg2 a table required, unknown usage
prompt -- opens a prompt window and stops the game until you press CANCEL or OK

### _G.gui functions:

register -- freezes emulator?

### _G.wgui functions:

tested:

wgui.fillrect(x, y, width, height, r, g, b)
wgui.fillrecta(0, 0, 150, 150, 0) -- arg 5 requires a string for some reason, unknown use
wgui.line(pos1x, pos1y, pos2x, pos2y)
wgui.info() -- returns width and height info as a table

e.g:
    local screen = wgui.info()
    wgui.fillrecta(0, 0, screen.width, screen.height, 0)

recommended loop for updating UIs is _emu.atupdatescreen(), using _emu.atinput (or emu.update) won't render anything

### _G.savestate functions:

savefile -- example: _G.savestate.savefile("saves/hello.st1")
loadfile -- example: _G.savestate.loadfile("saves/hello.st1")