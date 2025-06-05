-- Raycast.lua: Simulating and visualizing raycasts

---@class Raycast
Raycast = {}

-- This function simulates points in the space and checks if any is hit by a raycast (precise, slow)
---@param targetPos Vector3
---@param originPos Vector3
---@param direction Vector3
---@param length number
---@param distance number
---@param radius number
Raycast.multipleRayHits = function(originPos, targetPos, direction, length, distance, radius)
    for i = 1, length do
        local point = originPos + (direction * (i * distance))
        if point.distance(targetPos) < radius then
            return true
        end
    end
    return false
end

-- This function simulates a single raycast and checks if the object is hit (less precise, optimized)
Raycast.singleRayHits = function(originPos, targetPos, direction, length, distance, radius)
    -- unimplemented
end