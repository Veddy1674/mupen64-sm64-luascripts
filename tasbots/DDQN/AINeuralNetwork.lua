-- AINeuralNetwork.lua

local NN = {}
NN.__index = NN

function NN.new(inputSize, hiddenSize, outputSize, learningRate)
    local self = setmetatable({}, NN)
    self.inputSize = inputSize
    self.hiddenSize = hiddenSize
    self.outputSize = outputSize
    self.learningRate = learningRate

    local function rand(m)
        return math.random() * 2 * m - m
    end

    local limitIH = math.sqrt(1 / inputSize)
    local limitHO = math.sqrt(1 / hiddenSize)

    self.W1 = {}
    self.B1 = {}
    self.W2 = {}
    self.B2 = {}

    for i = 1, hiddenSize do
        self.W1[i] = {}
        for j = 1, inputSize do
            self.W1[i][j] = rand(limitIH)
        end
        self.B1[i] = rand(limitIH)
    end

    for i = 1, outputSize do
        self.W2[i] = {}
        for j = 1, hiddenSize do
            self.W2[i][j] = rand(limitHO)
        end
        self.B2[i] = rand(limitHO)
    end

    return self
end

local function relu(x) return math.max(0, x) end
local function drelu(x) return x > 0 and 1 or 0 end

function NN:predict(inputs)
    local h1 = {}
    for i = 1, self.hiddenSize do
        local sum = self.B1[i]
        for j = 1, self.inputSize do
            sum = sum + self.W1[i][j] * inputs[j]
        end
        h1[i] = relu(sum)
    end

    local out = {}
    for i = 1, self.outputSize do
        local sum = self.B2[i]
        for j = 1, self.hiddenSize do
            sum = sum + self.W2[i][j] * h1[j]
        end
        out[i] = sum
    end
    return out
end

function NN:train(inputs, targets)
    local h1, hsum = {}, {}
    for i = 1, self.hiddenSize do
        local sum = self.B1[i]
        for j = 1, self.inputSize do
            sum = sum + self.W1[i][j] * inputs[j]
        end
        hsum[i] = sum
        h1[i] = relu(sum)
    end

    local outputs, osum = {}, {}
    for i = 1, self.outputSize do
        local sum = self.B2[i]
        for j = 1, self.hiddenSize do
            sum = sum + self.W2[i][j] * h1[j]
        end
        osum[i] = sum
        outputs[i] = sum
    end

    for i = 1, self.outputSize do
        local error = targets[i] - outputs[i]
        for j = 1, self.hiddenSize do
            self.W2[i][j] = self.W2[i][j] + self.learningRate * error * h1[j]
        end
        self.B2[i] = self.B2[i] + self.learningRate * error
    end

    for i = 1, self.hiddenSize do
        local error = 0
        for k = 1, self.outputSize do
            error = error + (targets[k] - outputs[k]) * self.W2[k][i]
        end
        local grad = drelu(hsum[i]) * error
        for j = 1, self.inputSize do
            self.W1[i][j] = self.W1[i][j] + self.learningRate * grad * inputs[j]
        end
        self.B1[i] = self.B1[i] + self.learningRate * grad
    end
end

function NN:copy()
    local clone = NN.new(self.inputSize, self.hiddenSize, self.outputSize, self.learningRate)
    for i = 1, self.hiddenSize do
        for j = 1, self.inputSize do
            clone.W1[i][j] = self.W1[i][j]
        end
        clone.B1[i] = self.B1[i]
    end
    for i = 1, self.outputSize do
        for j = 1, self.hiddenSize do
            clone.W2[i][j] = self.W2[i][j]
        end
        clone.B2[i] = self.B2[i]
    end
    return clone
end

return NN
