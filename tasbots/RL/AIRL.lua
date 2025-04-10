-- AIRL.lua

local json = require("lib.json")
local aiState = require("tasbots.RL.AIState")
require("lua.misc.Utils")

---@class AIRLSettings
---@field alpha number
---@field base_epsilon number
---@field epsilonDecay number

---@class AIRL
---@field settings AIRLSettings
---@field actions string[]
---@field stateFormula fun():string
---@field savePath string
---@field frames number
---@field totalTickReward number
---@field leastTicks number
---@field episodeCounter number
---@field states AIState[]
---@field newStates AIState[]
---@field rewardPrevious fun(prevState:AIState, prevAction:string, reward:number)
---@field getTickAction fun():AIState, string
---@field nextEpisode fun(goodEnding:boolean, printInfo?:boolean)
---@field infoCurrentState fun()
---@field saveData fun()
---@field loadData fun()
local AIRL = {}
AIRL.__index = AIRL

---@param settings AIRLSettings
---@param actions string[]
---@param stateFormula fun():string
---@param savePath? string
---@return AIRL
function AIRL.new(settings, actions, stateFormula, savePath)
    local self = setmetatable({}, AIRL)
    
    self.settings = settings
    self.actions = actions
    self.stateFormula = stateFormula
    self.savePath = savePath or ""

    self.frames = 0
    self.totalTickReward = 0
    self.leastTicks = math.huge
    self.episodeCounter = 0

    self.states = {}
    self.newStates = {}

    -- local functions:
    ---@return AIState
    local function findStateOrNew()
        local stateID = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == stateID end)

        if not state then
            state = aiState.new(stateID, self.actions, self.settings)
            table.insert(self.states, state)
            table.insert(self.newStates, state)
        end
        return state
    end

    -- functions:
    function self.rewardPrevious(prevState, prevAction, reward)
        prevState.reward(prevAction, reward)

        self.totalTickReward = self.totalTickReward + reward
    end

    function self.getTickAction() -- reward is related to the changes that the prevAction caused
        
        local state = findStateOrNew()
        local newAction = state.getBestAction()
        
        self.frames = self.frames + 1
        return state, newAction
    end
    
    function self.nextEpisode(goodEnding, printInfo)
        printInfo = printInfo or false
    
        if goodEnding then
            if self.frames < self.leastTicks then
                self.leastTicks = self.frames
            end
        end

        self.episodeCounter = self.episodeCounter + 1
    
        if printInfo then
            printf("Episode %d (%s)", self.episodeCounter, goodEnding and "Success" or "Failure")
            printf("It took %d frames (%.2fs)", self.frames, self.frames / 30)
            printf("Least time: %d frames (%.2fs)", self.leastTicks, self.leastTicks / 30)
            printf("Total tick reward: %.2f", self.totalTickReward)
            printf(#self.newStates .. " new states from this episode\n")
        end
    
        self.frames = 0
        self.totalTickReward = 0
        self.newStates = {}
    end
    
    function self.infoCurrentState()
        local stateID = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == stateID end)
        if state then
            state:info()
        else
            emu.stop("State not found in infoCurrentState()")
        end
    end
    
    function self.saveData()
        if self.savePath == "" then emu.stop("No save path") end

        local file = io.open(self.savePath, "w")
        if not file then emu.stop("Can't open file: " .. self.savePath) end
        ---@cast file file*

        local statesData = {}
        for _, state in ipairs(self.states) do
            table.insert(statesData, {
                identifier = state.identifier,
                trust = state.trust,
                epsilon = state.epsilon,
            })
        end
        local data = {
            leastTicks = self.leastTicks == math.huge and -1 or self.leastTicks,
            episodeCounter = self.episodeCounter, -- todo remove?
            states = statesData
        }
    
        file:write(json.encode(data))
        file:close()
        printf("Data saved.\n")
    end
    
    function self.loadData()
        if self.savePath == "" then emu.stop("No save path") end

        local file = io.open(self.savePath, "r")
        if not file then
            -- create file
            file = io.open(self.savePath, "w")
            if not file then emu.stop("File not found and can't be created: " .. self.savePath) end
            ---@cast file file*
            
            file:write("{}")
            file:flush()
        end
        
        local raw = file:read("*a")
        if not raw or raw == "" or raw == "{}" then
            printf("No data found (loading for the first time).\n")
            file:close()
            return
        end
        local data = json.decode(raw)
        file:close()
        
        for _, stateData in ipairs(data.states) do
            local newState = aiState.new(stateData.identifier, self.actions, self.settings)
            newState.trust = stateData.trust
            newState.epsilon = stateData.epsilon

            table.insert(self.states, newState)
        end
        self.leastTicks = data.leastTicks == -1 and math.huge or data.leastTicks
        self.episodeCounter = data.episodeCounter
        printf("Data loaded.\n")
    end

    return self
end

return AIRL
