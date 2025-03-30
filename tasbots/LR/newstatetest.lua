-- Main.lua

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")

---@type Vector3[]
local states = {}

local function start() end

local function contains(tbl, element)
    for _, v in ipairs(tbl) do
        if v == element then return true end
    end
    return false
end

local defCoin = om.getObjects()[43]
local function update()
    local dx = mario.pos().x // 100
    local dy = mario.pos().y // 100
    local dz = mario.pos().z // 100
    local state = Vector3.new(dx, dy, dz)
    if not contains(states, state) then
        table.insert(states, state)
        print("New state: " .. state.info())

        -- make a coin to resemble state position
        local coin = om.duplicateObject(defCoin)
        memory.access(coin.base + 0x9C, INT, -1) -- disable collision
        coin.pos(state * 100)
    end
end

start()

_emu.atloadstate(function()
    for _, state in ipairs(states) do
        local coin = om.duplicateObject(defCoin)
        memory.access(coin.base + 0x9C, INT, -1) -- disable collision
        coin.pos(state * 100)
    end
end)

emu.update(update)