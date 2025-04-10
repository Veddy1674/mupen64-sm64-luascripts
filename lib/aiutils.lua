-- AIUtils.lua

---@param t table
---@return number
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
    return x > 0 and 1 or 0
end

---@param x number
---@return number
function sigmoid(x)
    return 1 / (1 + math.exp(-x))
end

---@param x number
---@return number
function dsigmoid(x)
    return x * (1 - x)
end

---@param x number
---@return number
function tanh(x) return math.hyperbolicTangent(x) end

---@param y number
---@return number
function dtanh(y) return 1 - y * y end