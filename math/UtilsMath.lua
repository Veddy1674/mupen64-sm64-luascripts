-- UtilsMath.lua

local module = {}

function module.round(number, decimals)
	decimals = decimals or 3 -- default 3
    local format_str = "%." .. decimals .. "f"
    return string.format(format_str, tonumber(number))
	-- e.g: string.format("%.5f", tonumber(number))
end

function module.approx(num1, num2, threshold) -- boolean
    threshold = threshold or 0.01
    return math.abs(num1 - num2) <= threshold
end

return module