-- AIDQN.lua

local AINeuralNetwork = require("lua.tasbots.DQN.AINeuralNetwork")
require("lua.lib.aiutils")
local json = require("lua.lib.json")

local function deepCopy2D(original)
    local copy = {}
    for i, row in ipairs(original) do
        copy[i] = {}
        for j, val in ipairs(row) do
            copy[i][j] = val
        end
    end
    return copy
end

local function deepCopy3D(original)
    local copy = {}
    for i, layer in ipairs(original) do
        copy[i] = {}
        for j, neuron in ipairs(layer) do
            copy[i][j] = {}
            for k, val in ipairs(neuron) do
                copy[i][j][k] = val
            end
        end
    end
    return copy
end

---@class AIDQN
---@field gamma number
---@field epsilon number
---@field inputs fun():number[]
---@field actions string[]
---@field network AINeuralNetwork
---@field targetNetwork AINeuralNetwork
---@field replayBuffer table<number[], integer, number, number[]>
---@field batchSize number
---@field bufferSize number
---@field episodes number
---@field remember fun(state:number[], actionIndex:integer, reward:number, nextState:number[])
---@field getAction fun(state:number[]):string, integer
---@field train fun()
---@field copyTarget fun()
---@field saveData fun(path:string)
---@field loadData fun(path:string|nil)
---@field graphInfo table<string, string>
---@field updateGraph fun(episode:number, avgReward:number)
---@field makeGraph fun(rewardPath:string, epsilonPath:string)
local AIDQN = {}
AIDQN.__index = AIDQN

---@param inputFunc fun():number[]
---@param sizes number[]
---@param learningRate number
---@param actions string[]
function AIDQN.new(inputFunc, sizes, gamma, learningRate, actions, replayBufferSize, batchSize)
    local self = setmetatable({}, AIDQN)
    self.gamma = gamma
    self.epsilon = 1.0
    self.inputs = inputFunc
    self.actions = actions

    self.replayBuffer = {}
    self.bufferSize = replayBufferSize or 2000
    self.batchSize =  batchSize or 128

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

    -- DOESN'T Update epsilon
    function self.train()
        if #self.replayBuffer < self.batchSize then return end

        for _ = 1, self.batchSize do
            local experience = self.replayBuffer[math.random(1, #self.replayBuffer)]
            local state, actionIndex, reward, nextState = table.unpack(experience)
    
            --! prediction happens here
            local qValues = self.network.predict(state)
            local nextQ = self.targetNetwork.predict(nextState)
    
            local target = {}
            for i = 1, #qValues do
                target[i] = qValues[i]
            end
            local noise = (math.random() - 0.5) * 0.01
            target[actionIndex] = reward + self.gamma * nextQ[argmax(nextQ)]-- + noise

            self.network.train(state, target)
        end
    end

    function self.copyTarget()
        for i, w in ipairs(self.network.weights) do
            for j = 1, #w do
                self.targetNetwork.weights[i][j] = w[j]
            end
        end
        for i = 1, #self.network.biases do
            self.targetNetwork.biases[i] = {}
            for j = 1, #self.network.biases[i] do
                self.targetNetwork.biases[i][j] = self.network.biases[i][j]
            end
        end
    end

    local function copyWeights(fromW, toW)
        for i = 1, math.min(#fromW, #toW) do --!
            for j = 1, math.min(#fromW[i], #toW[i]) do
                toW[i][j] = fromW[i][j]
            end
        end
    end

    local function copyBiases(fromB, toB)
        for i = 1, math.min(#fromB, #toB) do
            toB[i] = {}
            for j = 1, math.min(#fromB[i], #toB[i]) do
                toB[i][j] = fromB[i][j]
            end
        end
    end

    self.episodes = 0 -- does not update in real time!
    function self.saveData(path)
        local data = {
            layers = self.network.sizes,
            weights = self.network.weights,
            biases = self.network.biases,
            actions = self.actions,

            episodes = self.episodes,
            epsilon = self.epsilon, --!
            gamma = self.gamma, -- 0.99
            learningRate = self.network.learningRate, -- 0.0001
        }
        local file = io.open(path, "w")
        if not file then emu.stop("Unable to write in file " .. path, true) return end

        file:write(json.encode(data))
        file:close()

        print("Saved successfully to " .. path)
    end

    self.network = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")
    self.targetNetwork = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")

    function self.loadData(path)
        local function default()
            print("Loading for the first time.")

            self.network = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")
            self.targetNetwork = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")
            self.epsilon = 1.0
            self.episodes = 0
        end
        if path == nil then
            default()
            return
        end

        local file = io.open(path, "r")
        if not file then
            default()
            return
        end

        local data = json.decode(file:read("*a"))
        file:close()

        if not data or not data.layers then
            print("Corrupted or incomplete data file.")
            default()
            return --!
        end

        if not table.equals(data.layers, sizes) then
            printf("Previous net: (%s) does not match current net: (%s)",
                json.encode(data.layers), json.encode(sizes)
            )
            default()
            return
        end

        self.episodes = data.episodes -- overwrite
        self.actions = data.actions --! overwrite outputs
        self.epsilon = data.epsilon -- overwrite
        self.gamma = gamma

        self.network.weights = deepCopy3D(data.weights)
        self.network.biases = deepCopy2D(data.biases)
        self.targetNetwork.weights = deepCopy3D(data.weights)
        self.targetNetwork.biases = deepCopy2D(data.biases)

        self.network.learningRate = learningRate
        self.network.initialLearningRate = learningRate
        self.targetNetwork.learningRate = data.learningRate
        self.targetNetwork.initialLearningRate = data.learningRate

        print("Loaded successfully from " .. path)
    end

    self.graphInfo = {
        rewardCSV = "",
        epsilonCSV = "",
    }
    function self.updateGraph(episode, avgReward)
        self.graphInfo.rewardCSV = self.graphInfo.rewardCSV .. string.format("%d,%.2f\n", episode, avgReward) --!
        self.graphInfo.epsilonCSV = self.graphInfo.epsilonCSV .. string.format("%d,%.5f,%.5f\n", episode, self.epsilon, self.network.learningRate / self.network.initialLearningRate)
    end

    function self.makeGraph(rewardPath, epsilonPath)

        if rewardPath then
            local rewardStuff = io.open(rewardPath, "w")
            ---@cast rewardStuff file* (if it doesn't exist it just gets created)
            
            rewardStuff:write("Episode,AvgReward\n" .. self.graphInfo.rewardCSV)
            rewardStuff:close()
        end

        if epsilonPath then
            local epsilonStuff = io.open(epsilonPath, "w")
            ---@cast epsilonStuff file* (if it doesn't exist it just gets created)
            
            epsilonStuff:write("Episode,Epsilon,LearningRate\n" .. self.graphInfo.epsilonCSV)
            epsilonStuff:close()
        end
    end

    return self
end

return AIDQN
