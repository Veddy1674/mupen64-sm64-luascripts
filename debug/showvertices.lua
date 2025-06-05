-- A debug lua file

local om = require("lua.object.ObjectManager")
local ol = require("lua.object.ObjectList")
local mario = require("lua.mario.Mario")

local offset = Vector3.new(0, 30, 0)
local subdivisions = 3 -- recommended max: 4
local debugDistance = true
local coinsPerSide = (2^subdivisions) - 1

local function createCoin(type)
    local c = om.spawnObject("coin")
    local g = (type == 1 and ol["Blue Coin"].graphics) or (type == 2 and ol["Red Coin"].graphics) or ol["Coin"].graphics
    c.graphics(g)
    memory.access(c.base + 0x9C, INT, -1) -- disable collision
    return c
end

local prevFloor = nil
local cornerCoins = {}
local edgeCoins = {}

for side = 1, 3 do
    cornerCoins[side] = createCoin(1)
    edgeCoins[side] = {}
    for i = 1, coinsPerSide do
        edgeCoins[side][i] = createCoin(0)
    end
end

local function updateEdgeCoins(p1, p2, side)
    local step = 1 / (2^subdivisions)
    for i = 1, coinsPerSide do
        local t = step * i
        local pos = p1 * (1-t) + p2 * t
        edgeCoins[side][i].pos(pos + offset)
    end
end
---@cast prevFloor Triangle
print("Press UP to view your current distance to each vertice")

emu.update(function()
    local floor = mario.getFloorTriangle()
    if prevFloor == nil or prevFloor.base ~= floor.base then
        prevFloor = floor
        local vertices = floor.vertices()
        
        for side = 1, 3 do
            local nextSide = side % 3 + 1

			---@type Vector3
			local pos = vertices["p"..side]
            cornerCoins[side].pos(pos + offset)

            if subdivisions > 0 then
                updateEdgeCoins(vertices["p"..side], vertices["p"..nextSide], side)
            end
        end
    end

	if debugDistance and joypad.get().up then
		for i = 1, 3 do
			local pos = cornerCoins[i].pos()
			print("Dist from V" .. i .. ": " .. (pos.set("y", 0).distance(mario.pos().set("y", 0))))
		end
		print("-------------------------------------")
	end
end)