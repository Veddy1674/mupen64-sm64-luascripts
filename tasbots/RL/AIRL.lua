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
---@field stateFormula fun(): string
---@field savePath string
---@field frames number
---@field totalTickReward number
---@field leastTicks number
---@field episodeCounter number
---@field states AIState[]
---@field newStates AIState[]
---@field rewardPrevious fun(prevState: AIState, prevAction: string, reward: number)
---@field getTickAction fun(): AIState, string
---@field nextEpisode fun(goodEnding: boolean, printInfo?: boolean)
---@field infoCurrentState fun():AIState
---@field saveData fun()
---@field loadData fun()
local AIRL = {}
AIRL.__index = AIRL

---@param settings AIRLSettings
---@param stateFormula fun(): string
---@param savePath? string
---@return AIRL
function AIRL.new(settings, stateFormula, savePath)
    local self = setmetatable({}, AIRL)

    self.settings = settings
    self.stateFormula = stateFormula
    self.savePath = savePath or ""

    self.frames = 0
    self.totalTickReward = 0
    self.leastTicks = math.huge
    self.episodeCounter = 0

    self.states = {}
    self.newStates = {}

    ---@return AIState
    local function findOrCreateState()
        local id = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == id end)

        if not state then
            state = aiState.new(id, self.settings)
            table.insert(self.states, state)
            table.insert(self.newStates, state)
        end

        return state
    end

    ---@param prevState AIState
    ---@param prevAction string
    ---@param reward number
    function self.rewardPrevious(prevState, prevAction, reward)
        prevState.reward(prevAction, reward)
        self.totalTickReward = self.totalTickReward + reward
    end

    ---@return AIState, string
    function self.getTickAction()
        local state = findOrCreateState()
        local action = state.getBestAction()

        self.frames = self.frames + 1
        return state, action
    end

    ---@param goodEnding boolean
    ---@param printInfo? boolean
    function self.nextEpisode(goodEnding, printInfo)
        if goodEnding and self.frames < self.leastTicks then
            self.leastTicks = self.frames
        end

        self.episodeCounter = self.episodeCounter + 1

        if printInfo then
            printf("Episode %d (%s)", self.episodeCounter, goodEnding and "Success" or "Failure")
            printf("Frames: %d (%.2fs)", self.frames, self.frames / 30)
            printf("Best: %d (%.2fs)", self.leastTicks, self.leastTicks / 30)
            printf("Total reward: %.2f", self.totalTickReward)
            printf("New states: %d\n", #self.newStates)
        end

        self.frames = 0
        self.totalTickReward = 0
        self.newStates = {}
    end

    function self.infoCurrentState()
        local id = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == id end)

        if state then
            state:info()
        else emu.stop("State not found: infoCurrentState()") end

        ---@type AIState
        return nil
    end

    function self.saveData()
        if self.savePath == "" then return end

        local file = io.open(self.savePath, "w")
        if not file then emu.stop("Can't open file: " .. self.savePath) return end

        local data = {
            leastTicks = self.leastTicks == math.huge and -1 or self.leastTicks,
            episodeCounter = self.episodeCounter,
            states = {}
        }

        for _, state in ipairs(self.states) do
            table.insert(data.states, {
                identifier = state.identifier,
                trust = state.trust,
                epsilon = state.epsilon,
            })
        end

        file:write(json.encode(data))
        file:close()
        printf("Data saved.\n")
    end

    function self.loadData()
        if self.savePath == "" then return end

        local file = io.open(self.savePath, "r")
        if not file then
            file = io.open(self.savePath, "w")
            if not file then emu.stop("Cannot create file: " .. self.savePath) return end
            file:write("{}")
            file:flush()
            printf("Created empty data file.\n")
            return
        end

        local raw = file:read("*a")
        file:close()

        if not raw or raw == "" or raw == "{}" then
            printf("No data found, starting fresh.\n")
            return
        end

        local data = json.decode(raw)

        for _, s in ipairs(data.states) do
            local st = aiState.new(s.identifier, self.settings)
            st.trust = s.trust
            st.epsilon = s.epsilon
            table.insert(self.states, st)
        end

        self.leastTicks = data.leastTicks == -1 and math.huge or data.leastTicks
        self.episodeCounter = data.episodeCounter
        printf("Data loaded.\n")
    end

    return self
end

return AIRL
