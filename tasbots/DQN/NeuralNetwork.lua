-- NeuralNetwork.lua

---@class NeuralNetwork
---@field input_size number
---@field hidden_size number
---@field output_size number
---@field weights1 table
---@field weights2 table
---@field bias1 table
---@field bias2 table
---@field learning_rate number
local NeuralNetwork = {}
NeuralNetwork.__index = NeuralNetwork

math.randomseed(os.time())

---@param rows number
---@param cols number
---@return table
local function randomMatrix(rows, cols)
    local matrix = {}
    for i = 1, rows do
        matrix[i] = {}
        for j = 1, cols do
            matrix[i][j] = (math.random() * 2 - 1) * math.sqrt(1 / cols)
        end
    end
    return matrix
end

---@param vec table
---@return table
local function relu(vec)
    local result = {}
    for i = 1, #vec do
        result[i] = math.max(0, vec[i])
    end
    return result
end

---@param vec table
---@return table
local function relu_derivative(vec)
    local result = {}
    for i = 1, #vec do
        result[i] = vec[i] > 0 and 1 or 0
    end
    return result
end

---@param vec table
---@return number
local function maxIndex(vec)
    local maxVal = -math.huge
    local index = 1
    for i = 1, #vec do
        if vec[i] > maxVal then
            maxVal = vec[i]
            index = i
        end
    end
    return index
end

---@param input_size number
---@param hidden_size number
---@param output_size number
---@return NeuralNetwork
function NeuralNetwork.new(input_size, hidden_size, output_size)
    local self = setmetatable({}, NeuralNetwork)
    self.input_size = input_size
    self.hidden_size = hidden_size
    self.output_size = output_size
    self.weights1 = randomMatrix(hidden_size, input_size)
    self.weights2 = randomMatrix(output_size, hidden_size)
    self.bias1 = randomMatrix(hidden_size, 1)
    self.bias2 = randomMatrix(output_size, 1)
    self.learning_rate = 0.01
    return self
end

---@param state table
---@return table
function NeuralNetwork:forward(state)
    local hidden = {}
    for i = 1, self.hidden_size do
        hidden[i] = self.bias1[i][1]
        for j = 1, self.input_size do
            hidden[i] = hidden[i] + self.weights1[i][j] * state[j]
        end
    end
    hidden = relu(hidden)

    local output = {}
    for i = 1, self.output_size do
        output[i] = self.bias2[i][1]
        for j = 1, self.hidden_size do
            output[i] = output[i] + self.weights2[i][j] * hidden[j]
        end
    end
    return output
end

---@param state table
---@param action number
---@param target number
function NeuralNetwork:train(state, action, target)
    local hidden = {}  
    for i = 1, self.hidden_size do
        hidden[i] = self.bias1[i][1]
        for j = 1, self.input_size do
            hidden[i] = hidden[i] + self.weights1[i][j] * state[j]
        end
    end
    hidden = relu(hidden)

    local output = {}  
    for i = 1, self.output_size do
        output[i] = self.bias2[i][1]
        for j = 1, self.hidden_size do
            output[i] = output[i] + self.weights2[i][j] * hidden[j]
        end
    end

    local error = target - output[action] 

    for i = 1, self.hidden_size do
        self.weights2[action][i] = self.weights2[action][i] + self.learning_rate * error * hidden[i]
    end
    self.bias2[action][1] = self.bias2[action][1] + self.learning_rate * error

    local d_hidden = relu_derivative(hidden)
    for i = 1, self.hidden_size do
        for j = 1, self.input_size do
            self.weights1[i][j] = self.weights1[i][j] + self.learning_rate * error * d_hidden[i] * state[j]
        end
        self.bias1[i][1] = self.bias1[i][1] + self.learning_rate * error * d_hidden[i]
    end
end

return NeuralNetwork
