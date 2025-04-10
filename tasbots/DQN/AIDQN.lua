local AINeuralNetwork = require("lua.tasbots.DQN.AINeuralNetwork")
require("lua.lib.aiutils")

---@class AIDQN
---@field inputs fun(): number[]
---@field actions string[]
---@field network AINeuralNetwork
---@field epsilon number
---@field epsilonDecay number
---@field epsilonMin number
---@field giveReward fun(state: number[], action: string, reward: number, nextState: number[])
---@field getBestAction fun(): string
---@field train fun(action: string, reward: number)
local AIDQN = {}
AIDQN.__index = AIDQN

---@param inputFunc fun(): number[]
---@param hiddenNodes number
---@param actions string[]
---@param epsilonDecay number
---@param epsilonMin number
---@param learningRate number
---@param activationF "sigmoid"|"relu"|"tanh"
---@return AIDQN
function AIDQN.new(inputFunc, hiddenNodes, actions, epsilonDecay, epsilonMin, learningRate, activationF)
    local self = setmetatable({}, AIDQN)
    self.inputs = inputFunc
    self.actions = actions
    self.network = AINeuralNetwork.new(#inputFunc(), hiddenNodes, #actions, learningRate, activationF) --!
    self.epsilon = 1.0 -- start fully random
    self.epsilonDecay = epsilonDecay
    self.epsilonMin = epsilonMin

    -- get best action based on NN output
    function self.getBestAction()
        if math.random() < self.epsilon then
            return self.actions[math.random(#self.actions)]
        end

        local values = self.network.predict(self.inputs())
        local best = 1
        for i = 2, #values do
            if values[i] > values[best] then best = i end
        end
        return self.actions[best]
    end

    -- train the network
    function self.giveReward(state, action, reward, nextState)
        local target = self.network.predict(state)
        local nextQ = self.network.predict(nextState)
        local maxNextQ = valmax(nextQ)

        for i = 1, #self.actions do
            if self.actions[i] == action then
                target[i] = reward + 0.9 * maxNextQ
            end
        end

        self.network.train(state, target)
        self.epsilon = math.max(self.epsilon * self.epsilonDecay, self.epsilonMin)
    end

    return self

end

return AIDQN
