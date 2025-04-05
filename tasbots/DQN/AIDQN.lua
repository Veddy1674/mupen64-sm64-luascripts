-- AIDQN.lua

require("lua.misc.Utils")
local aiState = require("lua.tasbots.DQN.AIDQNState")
local neuralNetwork = require("lua.tasbots.DQN.NeuralNetwork")
local replayBuffer = require("lua.tasbots.DQN.ReplayBuffer")
local json = require("lib.json")
local aiutils = require("lib.aiutils")

---@class AIDQN : AIClass
---@field nn NeuralNetwork
---@field replayBuffer ReplayBuffer
---@field bufferFile string
---@field epsilon number
---@field epsilonDecay number
---@field gamma number
---@field saveTo fun()
---@field loadFrom fun()
---@field chooseAction fun(state:table):number
---@field train fun(batch_size:number)
---@field step fun(state:table, action:number, reward:number, next_state:table, done:boolean)
local AIDQN = {}
AIDQN.__index = AIDQN

---@param input_size number
---@param hidden_size number
---@param output_size number
---@param bufferFile string
---@return AIDQN
function AIDQN.new(input_size, hidden_size, output_size, bufferFile)
    local self = setmetatable({}, AIDQN)
    self.nn = neuralNetwork.new(input_size, hidden_size, output_size)
    self.replayBuffer = replayBuffer.new(10000) -- 10.000 limit
    self.bufferFile = bufferFile
    self.epsilon = 1.0
    self.epsilonDecay = 0.99
    self.gamma = 0.95

    function self.saveTo()
        local file = io.open(self.bufferFile, "w")
        if not file then emu.stop("File " .. self.bufferFile .. " not found!") return end
        file:write(json.encode(self.replayBuffer.buffer))
        file:close()
    end
    
    function self.loadFrom()
        local file = io.open(self.bufferFile, "r")
        if file then
            local content = file:read("*a")
            file:close()
            self.replayBuffer.buffer = json.decode(content) or {}
        end
    end
    
    function self.chooseAction(state)
        if math.random() < self.epsilon then
            return math.random(#self.nn.output_size) -- random action
        else
            local Q_values = self.nn:forward(state)
            return aiutils.argmax(Q_values) -- q max value action
        end
    end
    
    function self.train(batch_size)
        if #self.replayBuffer.buffer < batch_size then return end
        local batch = self.replayBuffer.getBatch(batch_size)
        
        for _, data in pairs(batch) do
            local state, action, reward, next_state, done = table.unpack(data)
            local target = reward
            if not done then
                local next_Q_values = self.nn:forward(next_state)
                target = target + self.gamma * next_Q_values[aiutils.argmax(next_Q_values)]
            end
            self.nn:train(state, action, target)
        end
    end
    
    function self.step(state, action, reward, next_state, done)
        self.replayBuffer.add(state, action, reward, next_state, done)
        self.train(32) -- batch size
        self.epsilon = math.max(0.1, self.epsilon * self.epsilonDecay) -- epsilon decaying
    end

    return self
end

return AIDQN