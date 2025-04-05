-- not a module

---@class Inputs
---@field A boolean?
---@field B boolean?
---@field Z boolean?
---@field Cleft boolean?
---@field Cright boolean?
---@field Cup boolean?
---@field Cdown boolean?
---@field L boolean?
---@field R boolean?
---@field start boolean?
---@field up boolean?
---@field down boolean?
---@field right boolean?
---@field left boolean?
---@field X number?
---@field Y number?

local Joypad = {}
Joypad.__index = Joypad

---@type nil
_joypad = _G.joypad

---@private
---@return Joypad
function Joypad.new()
    ---@class Joypad
    ---@field get fun(): Inputs
    ---@field set fun(inputs: Inputs)
    ---@field setOpposite fun(): Inputs
    ---@field add fun(inputs: Inputs)
    ---@field contains fun(input: string): boolean
    ---@field left Inputs
    ---@field right Inputs
    ---@field down Inputs
    ---@field up Inputs
    local self = setmetatable({}, Joypad)

    -- 100% range
    self.left = { X = -128 }
    self.right = { X = 127 }
    self.down = { Y = -128 }
    self.up = { Y = 127 }

    function self.set(inputs)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        _joypad.set(inputs)
    end

    function self.get()
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        return _joypad.get()
    end

    function self.setOppositeDirection()
        local inputs = self.get()
        self.add({ X = -inputs.X, Y = -inputs.Y })
        return self
    end

    function self.add(inputs)
        local saved = self.get()

        ---@type Inputs
        local newInputs = {}

        for input, value in pairs(saved) do
            newInputs[input] = inputs[input] or value
        end
        self.set(newInputs)
    end

    function self.contains(input)
        local inputs = self.get()
        return inputs[input] ~= nil and inputs[input] == true
    end

    return self
end

---@type Joypad
joypad = Joypad.new()