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

---@class Joypad
    ---@field get fun(): Inputs
    ---@field set fun(inputs: Inputs)
    ---@field setOppositeDirection fun(overwrite?: boolean): Inputs
    ---@field mix fun(inputs: Inputs): Inputs
    ---@field addall fun(inputs1: Inputs, inputs2: Inputs): Inputs
    ---@field add fun(inputs: Inputs): Inputs
    ---@field contains fun(input: string): boolean
    ---@field left Inputs
    ---@field right Inputs
    ---@field down Inputs
    ---@field up Inputs
    ---@field upleft Inputs
    ---@field upright Inputs
    ---@field downleft Inputs
    ---@field downright Inputs
    ---@field none Inputs
local Joypad = {}
Joypad.__index = Joypad

---@type nil
_joypad = _G.joypad

---@private
---@return Joypad
function Joypad.new()
    local self = setmetatable({}, Joypad)

    -- 100% range
    self.left = { X = -128, Y = 0 }
    self.right = { X = 127, Y = 0 }
    self.down = { Y = -128, X = 0 }
    self.up = { Y = 127, X = 0 }
    self.upleft = { X = -91, Y = 91 }
    self.upright = { X = 91, Y = 91 }
    self.downleft = { X = -91, Y = -91 }
    self.downright = { X = 91, Y = -91 }
    self.none = {} -- everything is set to false

    function self.set(inputs)
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        _joypad.set(inputs)
    end

    function self.get()
        ---@diagnostic disable-next-line: need-check-nil, undefined-field
        return _joypad.get()
    end

    function self.setOppositeDirection(overwrite)
        overwrite = overwrite or false

        local inputs = self.get()
        if overwrite then
            self.set({ X = -inputs.X, Y = -inputs.Y })
        else
            self.add({ X = -inputs.X, Y = -inputs.Y })
        end
        return inputs
    end

    -- Returns a new table with the mixed inputs
    function self.mix(inputs)
        local saved = self.get()

        ---@type Inputs
        local newInputs = {}

        for input, value in pairs(saved) do
            newInputs[input] = inputs[input] or value
        end
        return newInputs
    end

    -- Adds the inputs to the current inputs
    function self.add(inputs)
        local added = self.mix(inputs)
        self.set(added)
        return added
    end

    -- uh?
    function self.addall(inputs1, inputs2)
        ---@type Inputs
        local sum = {}

        sum.X = (inputs1.X or 0) + (inputs2.X or 0)
        sum.Y = (inputs1.Y or 0) + (inputs2.Y or 0)

        sum.A = (inputs1.A or false) or (inputs2.A or false)
        sum.B = (inputs1.B or false) or (inputs2.B or false)
        sum.Z = (inputs1.Z or false) or (inputs2.Z or false)
        sum.Cleft = (inputs1.Cleft or false) or (inputs2.Cleft or false)
        sum.Cright = (inputs1.Cright or false) or (inputs2.Cright or false)
        sum.Cup = (inputs1.Cup or false) or (inputs2.Cup or false)
        sum.Cdown = (inputs1.Cdown or false) or (inputs2.Cdown or false)
        sum.L = (inputs1.L or false) or (inputs2.L or false)
        sum.R = (inputs1.R or false) or (inputs2.R or false)
        sum.start = (inputs1.start or false) or (inputs2.start or false)
        sum.up = (inputs1.up or false) or (inputs2.up or false)
        sum.down = (inputs1.down or false) or (inputs2.down or false)
        sum.right = (inputs1.right or false) or (inputs2.right or false)
        sum.left = (inputs1.left or false) or (inputs2.left or false)

        self.set(sum)
        return sum
    end

    function self.contains(input)
        local inputs = self.get()
        return inputs[input] ~= nil and inputs[input] == true
    end

    return self
end

---@type Joypad
joypad = Joypad.new()