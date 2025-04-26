-- test.lua - Client test
-- A socket communication is made between lua (client) and python (server)

-- socket can not be required from a file that gets executed by Mupen64
-- no solution found to this day
local host, port = "localhost", 50001
local tcp = assert(socket.tcp())
tcp:settimeout(1)

if not tcp:connect(host, port) then
    emu.stop("No server found on port " .. port .. ". Make sure the server is running.")
    return
end

print("Connected with python server.")
local function sendAndReceive(msg)
    tcp:send(msg .. "\n")
    local response, err = tcp:receive("*l")
    if response then
        print("From Python:", response)
        return response
    else
        print("Error:", err)
    end
end

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
require("lua.tasbots.RL.actionInterpreter")

local savePath = "lua/tasbots/pyDQN/coincatch.st1"

local marioObj = mario.getObj()
local coin = om.getObjects()[172]
---@cast marioObj Object

-- decided externally
local minX, minZ, maxX, maxZ = -1958.787, -565.146, -1258.787, 234.854

local function reset()
    joypad.set({})

    -- random mario position
    local x = math.randomforcefloat(minX, maxX)
    local z = math.randomforcefloat(minZ, maxZ)
    mario.pos(Vector3.new(x, mario.pos().y, z))
    -- random coin position
    x = math.randomforcefloat(minX, maxX)
    z = math.randomforcefloat(minZ, maxZ)
    coin.pos(Vector3.new(x, coin.pos().y, z))
end

local function start()
    savestate.loadfile(savePath)
    reset()

    sendAndReceive("LuaReady")
end

local f = 0

local function update()
    f = f + 1
end

emu.start(start)
emu.update(update)
emu.stopped(function()
    print("Communication end.")
end)