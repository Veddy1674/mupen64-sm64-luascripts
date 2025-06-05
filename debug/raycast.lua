-- A debug lua file

local om = require("lua.object.ObjectManager")
local ol = require("lua.object.ObjectList")
local mario = require("lua.mario.Mario")

local radius = 5
local length = 6
local distance = 157.25
local directions = 4
local offset = Vector3.new(0, 80, 0)
local star = om.getObject(100)

local totalradius = ((star.hitbox().radius + radius) * 1.85) -- the multiplicative value was tested multiple times
if distance >= totalradius then
    print("Warning: Distance should be lower than distance / length, increase the length or decrease the distance.")
end
print("Recommended distance between objects: " .. totalradius .. " (for optimized results)")

local function yawToVector(rawYaw)
    local angle = (math.pi / 2) - (rawYaw / 65536) * (2 * math.pi)

    local vecX = math.cos(angle)
    local vecZ = math.sin(angle)

    return Vector3.new(vecX, 0, vecZ)
end

local function getDirectionsFromYaw(yaw, amount)
    local base = yawToVector(yaw)
    local dirs = {}

    local angles = {
        0, 45, -45, 90, -90, 180, 135, -135 -- f, fr, fl, r, l, b, br, bl
    }

    local presets = {
        [1] = {1},
        [2] = {1, 6},
        [3] = {1, 2, 3},
        [4] = {1, 4, 5, 6},
        [5] = {1, 2, 4, 3, 5},
        [6] = {1, 2, 3, 4, 5, 6},
        [7] = {1, 2, 3, 4, 5, 6, 7, 8},
        [8] = {1, 2, 4, 7, 6, 8, 5, 3}
    }

    for _, i in ipairs(presets[math.max(1, math.min(8, math.floor(amount)))]) do
        local a = math.rad(angles[i])
        local s, c = math.sin(a), math.cos(a)
        table.insert(dirs, Vector3.new(
            base.x * c - base.z * s,
            0,
            base.x * s + base.z * c
        ))
    end

    return dirs
end

local function visualizer(pos)
    local coin = om.spawnObject("coin", pos)
    memory.access(coin.base + 0x9C, INT, -1) -- disable collision
    return coin
end

local origin = visualizer(mario.pos() + offset)
---@type Object[]
local visualizers = {}
local dirs = getDirectionsFromYaw(mario.yawInfo().facing(), directions)
for d = 1, #dirs do
    for i = 1, length do
        local pos = mario.pos() + offset + (dirs[d] * (i * distance))
        table.insert(visualizers, visualizer(pos))
    end
end

local delay, f = 15, 0
emu.update(function()
    f = f + 1
    origin.pos(mario.pos() + offset)

    dirs = getDirectionsFromYaw(mario.yawInfo().facing(), directions)
    local index = 1
    for d = 1, #dirs do
        for i = 1, length do
            local pos = mario.pos() + offset + (dirs[d] * (i * distance))
            local vis = visualizers[index]
            vis.pos(pos)

            if vis.pos().distance(star.pos()) < (radius + star.hitbox().radius) then
                vis.graphics(ol["Red Coin"].graphics)
            else
                vis.graphics(ol["Coin"].graphics)
            end
            index = index + 1
        end
    end

    if f % delay == 0 then
        print("Ray hits: " .. tostring(
            Raycast.multipleRayHits(
                mario.pos() + offset, -- origin
                star.pos(), -- target
                yawToVector(mario.yawInfo().facing()), -- direction
                length, distance, radius + star.hitbox().radius -- params
            )
        ))
    end
end)

emu.stopped(function()
    if visualizers ~= nil and #visualizers > 0 then
        for i = 1, #visualizers do
            visualizers[i].clear()
        end
    end

    if origin ~= nil then
        origin.clear()
    end

    -- if dirs ~= nil and #dirs > 0 then
    --     for i = 1, #dirs do
    --         dirs[i].clear()
    --     end
    -- end
end)