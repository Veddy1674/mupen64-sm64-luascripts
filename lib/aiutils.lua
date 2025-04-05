-- AIUtils.lua

---@class AIUtils
local AIUtils = {}

---@param t table
---@return number
function AIUtils.argmax(t)
    local maxIndex, maxValue = 1, t[1]
    for i = 2, #t do
        if t[i] > maxValue then
            maxIndex, maxValue = i, t[i]
        end
    end
    return maxIndex
end

return AIUtils