-- AIDQN.lua

local AINeuralNetwork = require("lua.tasbots.DQN.AINeuralNetwork")
require("lua.lib.aiutils")
local json = require("lua.lib.json")

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
    
            --! prediction happens here
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
            toB[i][1] = fromB[i][1]
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
            epsilonDecay = self.epsilonDecay, -- 0.9998
            epsilonMin = self.epsilonMin, -- 0.05
            gamma = self.gamma, -- 0.99
            learningRate = self.network.learningRate, -- 0.0001
        }
        local file = io.open(path, "w")
        if not file then emu.stop("Unable to write in file " .. path, true) return end

        file:write(json.encode(data))
        file:close()

        print("Saved successfully to " .. path)
    end

    function self.loadData(path)
        local function default()
            print("Loading for the first time.")

            self.actions = actions
            self.network = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")
            self.targetNetwork = AINeuralNetwork.new(sizes, learningRate, 1.0, "relu", "none")
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
            default()
            return --!
        end

        self.episodes = data.episodes -- overwrite
        self.actions = data.actions --! overwrite outputs
        self.epsilon = data.epsilon -- overwrite
        self.epsilonDecay = data.epsilonDecay -- overwrite
        self.epsilonMin = data.epsilonMin -- overwrite
        self.gamma = data.gamma -- overwrite

        -- end early
        if table.equals(sizes,  data.layers) then
            self.network = AINeuralNetwork.new(sizes, data.learningRate, 1.0, "relu", "none")
            self.targetNetwork = AINeuralNetwork.new(sizes, data.learningRate, 1.0, "relu", "none")

            -- no copy, just overwrite
            -- self.network.weights = data.weights
            -- self.network.biases = data.biases
            -- self.targetNetwork.weights = data.weights
            -- self.targetNetwork.biases = data.biases
            copyWeights(data.weights, self.network.weights)
            copyBiases(data.biases, self.network.biases)
            copyWeights(data.weights, self.targetNetwork.weights)
            copyBiases(data.biases, self.targetNetwork.biases)

            print("Loaded successfully from " .. path)
            return
        end

        local endSizes = {} -- { 2, 8, 4 }
        if not table.equals(data.layers, sizes) then
            print("Different layers configuration found, trying to optimize...")

            if #data.layers ~= #sizes then
                emu.stop("Different number of layers, aborting.", true) -- TODO
                return
            end

            -- use the bigger config for each layer
            local inputCount = data.layers[1]
            endSizes[1] = inputCount > sizes[1] and inputCount or sizes[1]

            for i = 2, #data.layers - 1 do
                local hiddenCount = data.layers[i]
                endSizes[i] = hiddenCount > sizes[i] and hiddenCount or sizes[i]
            end

            local outputCount = data.layers[#data.layers]
            endSizes[#endSizes + 1] = outputCount > sizes[#sizes] and outputCount or sizes[#sizes]

            self.epsilon = 1.0 -- overwrite, has to re-learn (expecially if the output is different)
        end

        -- overwrite learningRate
        self.network = AINeuralNetwork.new(endSizes, data.learningRate, 1.0, "relu", "none")
        self.targetNetwork = AINeuralNetwork.new(endSizes, data.learningRate, 1.0, "relu", "none")

        -- restore some data:
        -- Input: must have the same size or data being bigger
        -- Hidden: can only copy till the smaller size
        -- Output: must have the same size or data is lost
        copyWeights(data.weights, self.network.weights)
        copyBiases(data.biases, self.network.biases)

        -- target
        copyWeights(data.weights, self.targetNetwork.weights)
        copyBiases(data.biases, self.targetNetwork.biases)

        print("Loaded (different) data successfully from " .. path)
        printf("Input before: %d, after: %d; Hidden before: %d, after: %d; Output before: %d, after: %d",
            data.layers[1], endSizes[1], data.layers[2], endSizes[2], data.layers[#data.layers], endSizes[#endSizes]
        )
    end

    self.graphInfo = {
        rewardCSV = "",
        epsilonCSV = "",
    }
    function self.updateGraph(episode, avgReward)
        self.graphInfo.rewardCSV = string.format("%s,%d\n", self.graphInfo.rewardCSV, episode, avgReward)
        self.graphInfo.epsilonCSV = string.format("%s,%d,%.5f,%.5f\n", self.graphInfo.epsilonCSV, episode, self.epsilon, self.network.learningRate / learningRate) --!
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
