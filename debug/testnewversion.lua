-- A debug lua file

function info(t, e)
	for key, value in pairs(t) do
		print(key, e or "")
	end
end

function start()
	--info(emu)
	info(console)
end

function update()
	
end

_G.start(start)

emu.atinput(update)

-- Differences noticed:
--[[

_G.start(func) seems to call the function before the first emulator frame (it's bad)
there are "wgui" and "gui"

-- wgui:
setfont	
info	no args, makes screen black for 1 frame
drawtext	
loadimage	
line	
drawimage	
setbk	
fillpolygona	
setpen	
text	returns nil, arg1: int (??) arg2: int (??), ??, does nothing??
fillrect	
fillellipsea		
polygon		returns nil, args: table (??), does nothing??
resize	
setbrush	
ellipse	
rect	
fillrecta	returns nil, args: int (pos x), int (pos y), int (size x), int (size y), string (??) - the string may be to save the rectangle to some table..
setcolor	

-- gui:
register - slow downs the game, then an error says "not enough memory" ???

]]