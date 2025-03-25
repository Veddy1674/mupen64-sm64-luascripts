-- UtilsMath.lua

local umath = {}

function umath.round(number, decimals)
	decimals = decimals or 3 -- default 3
    local format_str = "%." .. tostring(decimals) .. "f"
    return string.format(format_str, tonumber(number))
	-- e.g: string.format("%.5f", tonumber(number))
end

function umath.isApprox(num1, num2, threshold)
    threshold = threshold or 0.01
    return math.abs(num1 - num2) <= threshold
end

function umath.lerp(a, b, t)
    return a + (b - a) * t
end

return umath