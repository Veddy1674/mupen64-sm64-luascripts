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

local defCoin = om.getObject(43)
local factor = 100
-- 40: about 1.3 punches to change state
-- punches move mario by about 29 units

local function update()
    local dx = mario.pos().x // factor
    local dy = mario.pos().y // factor
    local dz = mario.pos().z // factor
    local state = Vector3.new(dx, dy, dz)
    if not contains(states, state) then
        table.insert(states, state)
        print("New state: " .. state.info())

        -- make a coin to resemble state position
        local coin = om.duplicateObject(defCoin)
        memory.access(coin.base + 0x9C, INT, -1) -- disable collision
        coin.pos(state * factor)
    end
end

emu.start(start)

_emu.atloadstate(function()
    for _, state in ipairs(states) do
        local coin = om.duplicateObject(defCoin)
        memory.access(coin.base + 0x9C, INT, -1) -- disable collision
        coin.pos(state * factor)
    end
end)

emu.update(update)