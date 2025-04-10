require("lua.lib.aiutils")

---@class AINeuralNetwork
---@field inputSize number
---@field hiddenSize number
---@field outputSize number
---@field weightsInputHidden number[][]
---@field weightsHiddenOutput number[][]
---@field biasHidden number[]
---@field biasOutput number[]
---@field learningRate number
---@field predict fun(inputs:number[]):number[]
---@field train fun(inputs:number[], targets:number[])
local AINeuralNetwork = {}
AINeuralNetwork.__index = AINeuralNetwork

---@param inputSize number
---@param hiddenSize number
---@param outputSize number
---@param learningRate number
---@param activationF "sigmoid"|"relu"|"tanh"
---@return AINeuralNetwork
function AINeuralNetwork.new(inputSize, hiddenSize, outputSize, learningRate, activationF)
    local self = setmetatable({}, AINeuralNetwork)
    self.inputSize = inputSize
    self.hiddenSize = hiddenSize
    self.outputSize = outputSize
    self.learningRate = learningRate

    -- init weights and biases
    self.weightsInputHidden = {}
    self.weightsHiddenOutput = {}
    self.biasHidden = {}
    self.biasOutput = {}

    -- xavier init
    local limitIH = math.sqrt(1 / inputSize)
    local limitHO = math.sqrt(1 / hiddenSize)

    for i = 1, hiddenSize do
        self.weightsInputHidden[i] = {}
        for j = 1, inputSize do
            self.weightsInputHidden[i][j] = math.random() * 2 * limitIH - limitIH
        end
        self.biasHidden[i] = 0
    end

    for i = 1, outputSize do
        self.weightsHiddenOutput[i] = {}
        for j = 1, hiddenSize do
            self.weightsHiddenOutput[i][j] = math.random() * 2 * limitHO - limitHO
        end
        self.biasOutput[i] = 0
    end

    -- local functions
    local activation = function(x)
        if activationF == "sigmoid" then
            return sigmoid(x)
        elseif activationF == "relu" then
            return relu(x)
        elseif activationF == "tanh" then
            return tanh(x)
        end
        emu.stop("Invalid activation")
    end

    local derivateActivation = function(x)
        if activationF == "sigmoid" then
            return dsigmoid(x)
        elseif activationF == "relu" then
            return drelu(x)
        elseif activationF == "tanh" then
            return dtanh(x)
        end
        emu.stop("Invalid activation")
    end

    -- predict output for given input
    function self.predict(inputs)
        -- hidden layer output
        local hiddenSums = {}
        local hiddenOutput = {}
        for i = 1, self.hiddenSize do
            local sum = self.biasHidden[i]
            for j = 1, self.inputSize do
                sum = sum + self.weightsInputHidden[i][j] * inputs[j]
            end
            hiddenSums[i] = sum
            hiddenOutput[i] = activation(sum)
        end

        -- output layer prediction
        local outputSums = {}
        local output = {}
        for i = 1, self.outputSize do
            local sum = self.biasOutput[i]
            for j = 1, self.hiddenSize do
                sum = sum + self.weightsHiddenOutput[i][j] * hiddenOutput[j]
            end
            outputSums[i] = sum
            output[i] = activation(sum)
        end
        return output
    end

    -- train with backprop
    function self.train(inputs, target)
        -- hidden layer
        local hiddenSums = {}
        local hiddenOutput = {}
        for i = 1, self.hiddenSize do
            local sum = self.biasHidden[i]
            for j = 1, self.inputSize do
                sum = sum + self.weightsInputHidden[i][j] * inputs[j]
            end
            hiddenSums[i] = sum
            hiddenOutput[i] = activation(sum)
        end
    
        -- output layer
        local outputSums = {}
        local outputs = {}
        for i = 1, self.outputSize do
            local sum = self.biasOutput[i]
            for j = 1, self.hiddenSize do
                sum = sum + self.weightsHiddenOutput[i][j] * hiddenOutput[j]
            end
            outputSums[i] = sum
            outputs[i] = activation(sum)
        end
    
        -- backprop output
        for i = 1, self.outputSize do
            local error = target[i] - outputs[i]
            local gradient = derivateActivation(outputSums[i]) * error * self.learningRate
    
            for j = 1, self.hiddenSize do
                self.weightsHiddenOutput[i][j] = self.weightsHiddenOutput[i][j] + gradient * hiddenOutput[j]
            end
    
            self.biasOutput[i] = self.biasOutput[i] + gradient
        end
    
        -- backprop hidden
        for i = 1, self.hiddenSize do
            local error = 0
            for j = 1, self.outputSize do
                error = error + (target[j] - outputs[j]) * self.weightsHiddenOutput[j][i]
            end
            local gradient = derivateActivation(hiddenSums[i]) * error * self.learningRate
    
            for j = 1, self.inputSize do
                self.weightsInputHidden[i][j] = self.weightsInputHidden[i][j] + gradient * inputs[j]
            end
    
            self.biasHidden[i] = self.biasHidden[i] + gradient
        end
    end    

    return self
end

return AINeuralNetwork
