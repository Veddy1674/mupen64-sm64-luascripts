-- AIDDQN.lua

local ReplayBuffer = require("lua.tasbots.DDQN.ReplayBuffer")
local NeuralNetwork = require("lua.tasbots.DDQN.AINeuralNetwork")

local DDQN = {}
DDQN.__index = DDQN

function DDQN.new(inputSize, hiddenSize, outputSize, learningRate, epsilonDecay, epsilonMin, bufferFilePath)
    local self = setmetatable({}, DDQN)

    self.qNetwork = NeuralNetwork.new(inputSize, hiddenSize, outputSize, learningRate)
    self.targetNetwork = self.qNetwork:copy()
    self.buffer = ReplayBuffer.new(bufferFilePath, 50000) -- max size
    self.outputSize = outputSize

    self.epsilon = 1.0
    self.epsilonDecay = epsilonDecay
    self.epsilonMin = epsilonMin

    self.gamma = 0.99
    self.updateTargetEvery = 1000
    self.steps = 0

    return self
end

function DDQN:getBestAction(state)
    if math.random() < self.epsilon then
        return math.random(self.outputSize)
    else
        local qValues = self.qNetwork:predict(state)
        local maxQ = qValues[1]
        local best = 1
        for i = 2, #qValues do
            if qValues[i] > maxQ then
                maxQ = qValues[i]
                best = i
            end
        end
        return best
    end
end

function DDQN:remember(state, action, reward, nextState, done)
    self.buffer:add(state, action, reward, nextState, done)
end

function DDQN:train(batchSize)
    if self.buffer:size() < batchSize then return end

    local batch = self.buffer:sample(batchSize)
    for _, experience in ipairs(batch) do
        local s, a, r, s2, done = table.unpack(experience)

        local target = self.qNetwork:predict(s)
        if done then
            target[a] = r
        else
            local nextQ = self.qNetwork:predict(s2)
            local nextQTarget = self.targetNetwork:predict(s2)
            local maxA = 1
            for i = 2, #nextQ do if nextQ[i] > nextQ[maxA] then maxA = i end end
            target[a] = r + self.gamma * nextQTarget[maxA]
        end

        self.qNetwork:train(s, target)
    end

    self.epsilon = math.max(self.epsilon * self.epsilonDecay, self.epsilonMin)
    self.steps = self.steps + 1
    if self.steps % self.updateTargetEvery == 0 then
        self.targetNetwork = self.qNetwork:copy()
    end
end

return DDQN
