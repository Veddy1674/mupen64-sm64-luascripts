-- actionInterpreter.lua

---@class ActionInterpreter
---@field toInputs fun(str: string): Inputs
---@field randomActions fun(): string
local reader = {}

---@type string[]
_buttons = {
    "A"
}
_directions = {
    "Left", "Right",
    "Up", "UpLeft", "UpRight",
    "Down", "DownLeft", "DownRight"
}

---@return Inputs
function reader.toInputs(str)
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
    local randomDirection = _directions[math.random(#_directions)]
    local randomButtonCombination = ""
    for i, button in ipairs(_buttons) do
        if math.random() < 0.5 then
            randomButtonCombination = randomButtonCombination .. button .. (i == #_buttons and "" or ",")
        end
    end
    return randomDirection .. (randomButtonCombination == "" and "" or "," .. randomButtonCombination)
    -- framelist example: [("Left","A"),("UpRight","B","Z")]
end

---@param currentState string
---@param promisingFramelist string[][] { {state, action} }
---@return string
function reader.customRandomActions(currentState, promisingFramelist, copyChance, mutationChance, randomChance)
    if #promisingFramelist == 0 then return reader.randomActions() end -- end early

    copyChance = copyChance or 0.3
    mutationChance = mutationChance or 0.6
    randomChance = randomChance or 0.1
    -- find what action was made in currentState (if any)
    local madeAction = nil
    for _, frame in ipairs(promisingFramelist) do
        if frame[1] == currentState then
            madeAction = frame[2]
            break
        end
    end
    local r = math.random()
    if madeAction == nil then
        return reader.randomActions()
    elseif r < copyChance then
        return madeAction
    elseif r < mutationChance then
        -- if was pressing A then not press, else press
        if string.find(madeAction, ",") then -- simplified, only removing/adding "A": remove last 2 characters
            return madeAction:sub(1, -3)
        else
            return madeAction .. ",A"
        end
    elseif r < randomChance then
        return reader.randomActions() -- exploration
    end
    return madeAction
end

---@return string
function reader.randomActions2()
    local direction = { "Left", "Right", "Up", "UpLeft", "UpRight" }
    return direction[math.random(#direction)]
end

---@param currentState string
---@param promisingFramelist string[][] { {state, action} }
---@return string
function reader.customRandomActions2(currentState, promisingFramelist, copyChance, mutationChance, randomChance)
    if #promisingFramelist == 0 then return reader.randomActions2() end -- end early

    copyChance = copyChance or 0.3
    mutationChance = mutationChance or 0.6
    randomChance = randomChance or 0.1
    -- find what action was made in currentState (if any)
    local madeAction = nil
    for _, frame in ipairs(promisingFramelist) do
        if frame[1] == currentState then
            madeAction = frame[2]
            break
        end
    end
    local r = math.random()
    if madeAction == nil then
        return reader.randomActions2()
    elseif r < copyChance then
        return madeAction
    elseif r < mutationChance then
        -- if was going left then 30% going up and 70% going upleft
        -- if was going right then 30% going up and 70% going upright
        -- if was going upleft then 30% going left and 70% going up
        -- if was going upright then 30% going right and 70% going up
        -- if was going up then 50% going upleft and 50% going upright
        if madeAction == "Left" then
            return math.random() < 0.3 and "Up" or "UpLeft"
        elseif madeAction == "Right" then
            return math.random() < 0.3 and "Up" or "UpRight"
        elseif madeAction == "UpLeft" then
            return math.random() < 0.3 and "Left" or "Up"
        elseif madeAction == "UpRight" then
            return math.random() < 0.3 and "Right" or "Up"
        elseif madeAction == "Up" then
            return math.random() < 0.5 and "UpLeft" or "UpRight"
        end
    elseif r < randomChance then
        return reader.randomActions2() -- exploration
    end
    return madeAction
end

return reader