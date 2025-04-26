-- playback.lua - To test the AI's prediction ability without training (epsilon = 0)

local mario = require("lua.mario.Mario")
local om = require("lua.object.ObjectManager")
local aiFactory = require("tasbots.DQN.AIDQN")
require("lua.tasbots.RL.actionInterpreter")

local savestatePath = "lua/tasbots/DQN/coinfollow.st1"
local savePath = "lua/tasbots/DQN/coinfollow.json"

local marioObj = mario.getObj()
local coin = om.getObjects()[43]
---@cast marioObj Object

-- creating ai
local function inputsFormula()
    local mx, _, mz = mario.pos().tuple()
    local cx, _, cz = coin.pos().tuple()
    local dx = (cx - mx)
    local dz = (cz - mz)

    return { -- everything normalized to 0-1
        dx / 1000, dz / 1000
    }
end

---@diagnostic disable-next-line: param-type-mismatch
local ai = aiFactory.new(inputsFormula, { 2, 8, 4 }, nil, nil, nil, nil, nil)
ai.loadData(savePath)

local function doingBadAction()
    return marioObj.distanceFrom(coin) > 1000
end

local function moveCoin(output)
    if joypad.get().up then print(output) end
    if output == "Left" then
        coin.pos(coin.pos() + Vector3.new(-5, 0, 0))
    elseif output == "Right" then
        coin.pos(coin.pos() + Vector3.new(5, 0, 0))
    elseif output == "Up" then
        coin.pos(coin.pos() + Vector3.new(0, 0, -5))
    elseif output == "Down" then
        coin.pos(coin.pos() + Vector3.new(0, 0, 5))
    end
end

-- decided externally
local minX, minZ, maxX, maxZ = -1764.012,-1709.436,-1362.912,-702.1326

local function reset()
    -- joypad.set({})

    -- random coin position
    local x = math.randomforcefloat(minX, maxX)
    local z = math.randomforcefloat(minZ, maxZ)
    coin.pos(Vector3.new(x, coin.pos().y, z))
end

local function start()
    savestate.loadfile(savestatePath)
    reset()
end

local function update()

    moveCoin(ai.getAction(inputsFormula())) -- move coin based on AI prediction
    -- joypad.set({}) -- avoid inputs

    local failed = doingBadAction()
    local success = coin.overlapsWith(marioObj)

    if success or failed then
        reset()
        return --!
    end
end

emu.start(start)
emu.update(update)
emu.stopped(function(crashed)
    reset()
    if crashed then return end
    print("called stop")
end)

-- a little important and nice detail to note:
-- the AI learns to understand its own and mario's hitbox without it being an input,
-- because it is trained to end as quickly as possible