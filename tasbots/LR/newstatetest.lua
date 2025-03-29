-- Main.lua

local mario = require("lua.mario.Mario")

---@type Vector3[]
local states = {}

local function start() end

local function contains(tbl, element)
    for _, v in ipairs(tbl) do
        if v == element then return true end
    end
    return false
end

local function update()
    local dx = math.floor(mario.pos.x / 100)
    local dy = math.floor(mario.pos.y / 100)
    local dz = math.floor(mario.pos.z / 100)
    local state = Vector3.new(dx, dy, dz)
    if not contains(states, state) then
        table.insert(states, state)
        print("New state: " .. state.info())
    end
end

start()

emu.update(function()
    update()
end)