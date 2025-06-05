-- AINeuralNetwork.lua

require("lua.lib.aiutils")
require("lua.misc.Utils") -- math.randomforcefloat?

---@class AINeuralNetwork
---@field sizes number[]
---@field weights number[][][]
---@field biases number[][]
---@field initialLearningRate number
---@field learningRate number
---@field predict fun(inputs:number[]):number[]
---@field train fun(inputs:number[], targets:number[])
local AINeuralNetwork = {}
AINeuralNetwork.__index = AINeuralNetwork

---@param sizes number[]
---@param learningRate number
---@param decayLearningRate number
---@param activationHidden "none"|"relu"|"sigmoid"|"tanh"
---@param activationOutput "none"|"relu"|"sigmoid"|"tanh"
function AINeuralNetwork.new(sizes, learningRate, decayLearningRate, activationHidden, activationOutput)
    local self = setmetatable({}, AINeuralNetwork)
    self.sizes = sizes
    self.learningRate = learningRate
    self.initialLearningRate = learningRate

    self.weights = {}
    self.biases = {}

    local function getActivation(act, x)
        if act == "relu" then return relu(x) end
        if act == "sigmoid" then return sigmoid(x) end
        if act == "tanh" then return tanh(x) end
        return x
    end

    local function getActivationDerivative(act, x)
        if act == "relu" then return drelu(x) end
        if act == "sigmoid" then return dsigmoid(x) end
        if act == "tanh" then return dtanh(x) end
        return 1
    end

    local function initWeights(rows, cols)
        local limit = math.sqrt(1 / cols)
        local m = {}
        for i = 1, rows do
            m[i] = {}
            for j = 1, cols do
                m[i][j] = math.random() * 2 * limit - limit
            end
        end
        return m
    end

    for l = 2, #sizes do
        table.insert(self.weights, initWeights(sizes[l], sizes[l - 1]))
        local bias = {}
        for i = 1, sizes[l] do bias[i] = 0.01 end
        table.insert(self.biases, bias)
    end

    function self.predict(inputs)
        local a = inputs
        for l = 1, #self.weights do
            local nextA = {}
            for i = 1, self.sizes[l + 1] do
                local sum = self.biases[l][i]
                for j = 1, self.sizes[l] do
                    sum = sum + self.weights[l][i][j] * a[j]
                end
                nextA[i] = (l == #self.weights) and
                    getActivation(activationOutput, sum) or getActivation(activationHidden, sum)
            end
            a = nextA
        end
        return a
    end

    function self.train(inputs, targets)
        local activations = { inputs }
        local sums = {}

        -- Forward pass
        for l = 1, #self.weights do
            local a = activations[#activations]
            local sum = {}
            local nextA = {}
            for i = 1, self.sizes[l + 1] do
                local s = self.biases[l][i]
                for j = 1, self.sizes[l] do
                    s = s + self.weights[l][i][j] * a[j]
                end
                sum[i] = s
                nextA[i] = (l == #self.weights) and
                    getActivation(activationOutput, s) or getActivation(activationHidden, s)
            end
            table.insert(sums, sum)
            table.insert(activations, nextA)
        end

        -- Backward pass
        local deltas = {}
        local L = #self.weights

        -- Output delta
        local lastDelta = {}
        for i = 1, self.sizes[L + 1] do
            lastDelta[i] = targets[i] - activations[L + 1][i]
        end
        deltas[L] = lastDelta

        -- Hidden layers
        for l = L - 1, 1, -1 do
            local delta = {}
            for i = 1, self.sizes[l + 1] do
                local error = 0
                for j = 1, self.sizes[l + 2] do
                    error = error + deltas[l + 1][j] * self.weights[l + 1][j][i]
                end
                delta[i] = error * getActivationDerivative(activationHidden, sums[l][i])
            end
            deltas[l] = delta
        end        

        -- Update weights and biases
        for l = 1, L do
            for i = 1, self.sizes[l + 1] do
                for j = 1, self.sizes[l] do
                    self.weights[l][i][j] = self.weights[l][i][j] + self.learningRate * deltas[l][i] * activations[l][j]
                end
                self.biases[l][i] = self.biases[l][i] + self.learningRate * deltas[l][i]
            end
        end

        -- Update learning rate
        -- (The network is meant to be used in real-time training, aka not with epochs, if you use epochs,
        -- make sure to keep the decayLearningRate extremely close to 1 (e.g 0.99999...) or keep it at 1 to
        -- avoid the console from getting flooded by warnings and get your emulator frozen)
        if decayLearningRate ~= 1 then
            self.learningRate = self.learningRate * (decayLearningRate)
            if self.learningRate < 0.00001 then
                print("(warn) Learning rate is low: " .. self.learningRate)
            elseif self.learningRate > 0.1 then
                print("(warn) Learning rate is high: " .. self.learningRate)
            end
        end
    end

    return self
end

return AINeuralNetwork
