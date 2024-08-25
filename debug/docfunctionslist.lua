-- A debug lua file for doc.txt

function printFunctions()
	for k, v in pairs() do
		if type(v) == "function" then
			print(k)
		end
	end
end
--[[ Custom functions found from _G

	savestate -- emulator savestate manager
	movie -- emulator movie manager
	tostringex
	start -- _G.start(startfunction) to make sure the code starts at the first emulator frame (if the game is paused for example..)
	avi -- emulator avi movie manager
	d2d
	wgui
	input
	printx
	joypad -- emulator joypad manager
	emu -- emulator functions
	memory -- emulator memory
	iohelper -- input output helper?
	stop -- forces code stop

--]]

local function printInfo(func)
    local info = debug.getinfo(func)
    print("Function: " .. (info.name or "unknown"))
    print("Defined in: " .. (info.source or "unknown"))
    print("Line defined: " .. (info.linedefined or "unknown"))
	
    local numParams = info.nparams
    print("Number of parameters: " .. numParams)
end

printFunctionInfo(memory)