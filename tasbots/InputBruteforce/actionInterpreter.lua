-- actionInterpreter.lua

---@class ActionInterpreter
---@field toInputs fun(str: string): Inputs
---@field randomActions fun(): string
local reader = {}

---@type string[]
local buttons = {
    "A"
}
local directions = {
    "Left", "Right",
    "Up", "UpLeft", "UpRight",
    "Down", "DownLeft", "DownRight"
}

---@return Inputs
function reader.toInputs(str)
    str = str:sub(1, -1) -- remove parentheses

    local parts = string.split(str, ",")
    local direction = parts[1]:lower()
    local inputs = {}

    local stick = joypad[direction]
    inputs.X = stick.X
    inputs.Y = stick.Y

    -- add buttons (if there)
    for i = 2, #parts do
        local btn = parts[i] -- "A"
        inputs[btn] = true
    end
    
    return inputs
end

---@return string
function reader.randomActions()
    local randomDirection = directions[math.random(#directions)]
    local randomButtonCombination = ""
    for i, button in ipairs(buttons) do
        if math.random() > 0.5 then
            randomButtonCombination = randomButtonCombination .. button .. (i == #buttons and "" or ",")
        end
    end
    return randomDirection .. "," .. randomButtonCombination
    -- Example: [("Left","A"),("UpRight","B","Z")]
end

return reader