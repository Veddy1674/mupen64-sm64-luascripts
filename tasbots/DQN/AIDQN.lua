-- AIDQN.lua

local AINeuralNetwork = require("lua.tasbots.DQN.AINeuralNetwork")
require("lua.lib.aiutils")

local function tblRep(value, count)
    local t = {}
    for i = 1, count do t[i] = value end
    return t
end

---@class AIDQN
---@field network AINeuralNetwork
---@field gamma number
---@field epsilon number
---@field epsilonDecay number
---@field epsilonMin number
---@field inputs fun():number[]
---@field outputs number
---@field memorySize number
---@field pastActions number[][]
---@field getBestAction fun():number[]
---@field giveReward fun(state:number[], actionVec:number[], reward:number, nextState:number[])
local AIDQN = {}
AIDQN.__index = AIDQN

function AIDQN.new(inputFunc, hiddenNodes, outputs, epsilonDecay, epsilonMin, learningRate, activationF, memorySize)
    local self = setmetatable({}, AIDQN)
    self.gamma = 0.99
    self.epsilon = 1.0
    self.epsilonDecay = epsilonDecay
    self.epsilonMin = epsilonMin
    self.inputs = inputFunc
    self.outputs = outputs
    self.memorySize = memorySize or 4
    self.pastActions = {}
    for i = 1, self.memorySize do self.pastActions[i] = tblRep(0, outputs) end

    local function getFullInput()
        local input = self.inputs()
        for _, actVec in ipairs(self.pastActions) do
            for _, v in ipairs(actVec) do
                table.insert(input, v)
            end
        end
        return input
    end

    self.network = AINeuralNetwork.new(#getFullInput(), hiddenNodes, outputs, learningRate, activationF)

    function self.getBestAction()
        local output = self.network.predict(getFullInput())
        print("Raw Output: ", table.concat(output, ", "))
        for i = 1, #output do
            output[i] = clamp(output[i] * 254 - 127, -127, 127)
        end
        if math.random() < self.epsilon then
            local noisy = {}
            for i = 1, #output do
                noisy[i] = clamp(output[i] + (math.random() * 2 - 1) * 5, -127, 127)
            end
            return noisy
        end
        return output
    end

    local function updatePastActions(vec)
        table.remove(self.pastActions, 1)
        table.insert(self.pastActions, vec)
    end

    function self.giveReward(state, actionVec, reward, nextState)
        local fullState = {table.unpack(state)}
        for _, a in ipairs(self.pastActions) do for _, v in ipairs(a) do table.insert(fullState, v) end end

        updatePastActions(actionVec)

        local fullNext = {table.unpack(nextState)}
        for _, a in ipairs(self.pastActions) do for _, v in ipairs(a) do table.insert(fullNext, v) end end

        local target = self.network.predict(fullState)
        local nextQ = self.network.predict(fullNext)
        local maxNextQ = argmaxi(nextQ)

        -- for i = 1, self.outputs do
        --     target[i] = reward + self.gamma * nextQ[i]
        -- end
        for i = 1, #target do
            target[i] = reward + (self.gamma * maxNextQ)
        end

        self.network.train(fullState, target)
        self.epsilon = math.max(self.epsilon * self.epsilonDecay, self.epsilonMin)
    end

    return self
end

return AIDQN
