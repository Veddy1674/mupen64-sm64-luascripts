-- AIUtils.lua

---@param t table
---@return any
function argmax(t)
    local maxKey, maxValue = next(t)
    for key, value in pairs(t) do
        if value > maxValue then
            maxKey, maxValue = key, value
        end
    end
    ---@cast maxKey number
    return maxKey
end

---@param t table
---@return any
function argmaxi(t)
    local max = -math.huge
    local index = 1
    for i, v in ipairs(t) do
        if v > max then
            max = v
            index = i
        end
    end
    return index
end

---@param t table
---@return number
function valmax(t)
    local maxValue = next(t) and select(2, next(t)) or error("Table is empty!")
    for _, value in pairs(t) do
        if value > maxValue then
            maxValue = value
        end
    end
    return maxValue
end

---@param x number
---@return number
function relu(x)
    return math.max(0, x)
end

---@param x number
---@return number
function drelu(x)
    return (x > 0) and 1 or 0
end

---@param x number
---@return number
function sigmoid(x)
    return 1 / (1 + math.exp(-x))
end

---@param x number
---@return number
function dsigmoid(x)
    local s = sigmoid(x)
    return s * (1 - s)
end

---@param x number
---@return number
function tanh(x)
    return math.hyperbolicTangent(x)
end

---@param x number
---@return number
function dtanh(x)
    local t = tanh(x)
    return 1 - (t * t)
end

---@param x number
---@param min number
---@param max number
---@return number
function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

---@param rawYaw number
---@return Vector3
function yawToVector(rawYaw)
    local angle = (math.pi / 2) - (rawYaw / 65536) * (2 * math.pi)

    local vecX = math.cos(angle)
    local vecZ = math.sin(angle)

    return Vector3.new(vecX, 0, vecZ)
end