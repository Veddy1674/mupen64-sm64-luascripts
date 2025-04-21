-- AIDQN.lua

local AINeuralNetwork = require("lua.tasbots.DQN.AINeuralNetwork")
require("lua.lib.aiutils")

---@class AIDQN
---@field gamma number
---@field epsilon number
---@field epsilonDecay number
---@field epsilonMin number
---@field inputs fun():number[]
---@field actions string[]
---@field network AINeuralNetwork
---@field targetNetwork AINeuralNetwork
---@field replayBuffer table<number[], integer, number, number[]>
---@field batchSize number
---@field bufferSize number
---@field remember fun(state:number[], actionIndex:integer, reward:number, nextState:number[])
---@field getAction fun(state:number[]):string, integer
---@field train fun()
---@field copyTarget fun()
local AIDQN = {}
AIDQN.__index = AIDQN

---@param inputFunc fun():number[]
---@param sizes number[]
---@param learningRate number
---@param epsilonDecay number
---@param epsilonMin number
---@param actions string[]
function AIDQN.new(inputFunc, sizes, gamma, learningRate, epsilonDecay, epsilonMin, actions)
    local self = setmetatable({}, AIDQN)
    self.gamma = gamma
    self.epsilon = 1.0
    self.epsilonDecay = epsilonDecay
    self.epsilonMin = epsilonMin
    self.inputs = inputFunc
    self.actions = actions

    self.replayBuffer = {}
    self.bufferSize = 2000
    self.batchSize = 128

    self.network = AINeuralNetwork.new(sizes, learningRate)
    self.targetNetwork = AINeuralNetwork.new(sizes, learningRate)

    function self.remember(state, actionIndex, reward, nextState)
        table.insert(self.replayBuffer, { state, actionIndex, reward, nextState })
        if #self.replayBuffer > self.bufferSize then
            table.remove(self.replayBuffer, 1)
        end
    end

    function self.getAction(state) -- as argument because why not
        -- local state = self.inputs()
        local qValues = self.network.predict(state)
    
        if math.random() < self.epsilon then
            local randIndex = math.random(1, #self.actions)
            return self.actions[randIndex], randIndex
        end
    
        local bestIndex = argmax(qValues)
        -- print(bestIndex)
        return self.actions[bestIndex], bestIndex
    end

    -- Updates epsilon
    function self.train()
        if #self.replayBuffer < self.batchSize then return end

        for _ = 1, self.batchSize do
            local experience = self.replayBuffer[math.random(1, #self.replayBuffer)]
            local state, actionIndex, reward, nextState = table.unpack(experience)
    
            local qValues = self.network.predict(state)
            local nextQ = self.targetNetwork.predict(nextState)
    
            local target = {}
            for i = 1, #qValues do
                target[i] = qValues[i]
            end
            target[actionIndex] = reward + self.gamma * nextQ[argmax(nextQ)] + (math.random() - 0.5) * 0.01

            self.network.train(state, target)
        end
    
        self.epsilon = math.max(self.epsilon * self.epsilonDecay, self.epsilonMin)
    end

    function self.copyTarget()
        for i, w in ipairs(self.network.weights) do
            for j = 1, #w do
                self.targetNetwork.weights[i][j] = w[j]
            end
        end
    end

    return self
end

return AIDQN
