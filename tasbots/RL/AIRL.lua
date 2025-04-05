require("lua.misc.Utils")
local json = require("lib.json")
local aiState = require("tasbots.RL.AIState")

---@class AIRLSettings
---@field alpha number
---@field gamma number
---@field base_epsilon number
---@field epsilonDecay number

---@class AIRL
---@field settings AIRLSettings
---@field actions ActionMap
---@field stateFormula fun():string
---@field tickRewardFormula fun():number
---@field generationRewardFormula fun():number
---@field actionConditions fun(actionName:string):boolean
---@field frames number
---@field totalTickReward number
---@field leastTicks number -- best time
---@field states AIState[]
---@field newStates AIState[]
---@field previousFrameData { state:AIState, actionName:string, reward:number }|nil
---@field genCounter number
---@field savePath string
---@field getTickAction fun():Inputs
---@field nextGeneration fun(printInfo?:boolean)
---@field saveData fun()
---@field loadData fun()
---@field infoCurrentState fun()
local ai = {}
ai.__index = ai

---@param settings AIRLSettings
---@param actions table
---@param stateFormula fun():string
---@param tickRewardFormula fun():number
---@param generationRewardFormula fun():number
---@param savePath? string
---@return AIRL
function ai.new(settings, actions, stateFormula, tickRewardFormula, generationRewardFormula, actionConditions, savePath)
    local self = setmetatable({}, ai)

    self.settings = {
        alpha = settings.alpha, -- learning rate
        gamma = settings.gamma, -- discount factor
        base_epsilon = settings.base_epsilon, -- start exploration (global, for new states)
        epsilonDecay = settings.epsilonDecay, -- exploration decay (global)
    }
    
    self.actions = actions -- { right = joypad.right ... end }

    self.stateFormula = stateFormula
    self.tickRewardFormula = tickRewardFormula
    self.generationRewardFormula = generationRewardFormula
    self.actionConditions = actionConditions
    self.frames = 0 -- resets every new generation
    self.totalTickReward = 0 -- resets every new generation
    self.leastTicks = math.huge -- global

    self.states = {}
    self.newStates = {}
    
    self.previousFrameData = nil
    self.genCounter = 0

    self.savePath = savePath or ""

    -- Global Functions
    function self.getTickAction()
        -- Find already existing state or create new one
        local stateID = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == stateID end)
        
        if state == nil then -- unknown state
            state = aiState.new(stateID, self.actions, self.settings)
            table.insert(self.states, state)
            table.insert(self.newStates, state)
        end

        ---@type string
        local bestActionName = state.getBestActionName(self.actionConditions)

        -- mini-reward (usually related to distance)
        local reward = self.tickRewardFormula()

        -- q-learning (updates previous action first)
        -- previous action is rewarded even if the state is the same
        if self.previousFrameData ~= nil then -- it's nil on the first and last frame
            self.previousFrameData.state.updateTrustFor(
                self.previousFrameData.actionName, reward - self.previousFrameData.reward
            )
        end
        self.previousFrameData = {
            state = state,
            actionName = bestActionName,
            reward = reward
        }

        self.totalTickReward = self.totalTickReward + reward
        self.frames = self.frames + 1

        ---@type Inputs
        return self.actions[bestActionName]
    end

    function self.nextGeneration(printInfo)
        printInfo = printInfo or false
        -- update stuff
        self.genCounter = self.genCounter + 1
        self.previousFrameData = nil -- avoid last action's trust to be updated
        local genReward = self.generationRewardFormula() -- currently unused
        --k

        -- reset
        if self.frames < self.leastTicks then
            self.leastTicks = self.frames
        end

        if printInfo then
            print("Generation " .. self.genCounter)
            print(string.format("It took %d frames (%.2fs)", self.frames, self.frames / 30))
            print(string.format("Least time: %d frames (%.2fs)", self.leastTicks, self.leastTicks / 30))
            print(string.format("Generation reward: %.2f", genReward))
            print(string.format("Total tick reward: %.2f", self.totalTickReward))
            print(#self.newStates .. " new states from this generation")
            print()
        end

        self.frames = 0
        self.totalTickReward = 0
        self.newStates = {}
    end
    
    function self.infoCurrentState()
        local stateID = self.stateFormula()
        local state = table.compare(self.states, function(s) return s.identifier == stateID end)

        ---@cast state AIState
        if state then
            state.info()
        else
            emu.stop("Error trying to find a state in AIRL.infoCurrentState()")
        end
    end

    function self.saveData()
        if self.saveData == "" then emu.stop("Cannot save: no save path") end

        local file = io.open(self.savePath, "w")
        if not file then emu.stop("File " .. self.savePath .. " not found") end
        ---@cast file file*

        local data = {
            states = self.states,
            leastTicks = self.leastTicks,
        }
        file:write(json.encode(data))
        file:close()

        print("Data saved successfully.")
        print()
    end

    function self.loadData()
        if self.saveData == "" then emu.stop("Cannot save: no save path") end

        local file = io.open(self.savePath, "r")
        if not file then emu.stop("File " .. self.savePath .. " not found") end
        ---@cast file file*
        
        local data = json.decode(file:read("*a"))
        file:close()
        if data.states == nil then -- if one of the fields is missing then there's no data (first time)
            print("No data found.")
            print()
            return
        end

        for _, state in pairs(data.states) do
            table.insert(self.states, aiState.new(state.identifier, self.actions, self.settings))
        end
        self.leastTicks = data.leastTicks

        print("Data loaded successfully.")
        print()
    end

    return self
end

return ai
