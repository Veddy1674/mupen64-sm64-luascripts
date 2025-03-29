local json = require("lib.json")
local mathDist = require("lua.math.Distance")
local mario = require("lua.mario.Mario")

---@class AIRLSettings
---@field alpha number
---@field gamma number
---@field epsilon number
---@field epsilonDecay number

---@class AIRL
---@field settings AIRLSettings
---@field trust table
---@field state number[]
---@field actions table -- [string] : fun()
---@field actionHistory table -- ??
---@field goalObj Object
---@field stateFormula fun():string
---@field tickRewardFormula fun():number
---@field generationRewardFormula fun(ticksTaken:number):number
---@field totalTickReward number
---@field bestTime number
---@field getDistance fun():Vector3
---@field performAction fun(boolean)
---@field updateTrust fun(timeTaken:number):number,number
---@field saveTrustData fun(saveFile:string|nil)
---@field loadTrustData fun(saveFile:string|nil)
---@field info fun()
local ai = {}
ai.__index = ai

---@param settings AIRLSettings
---@param actions table
---@param goalObj Object
function ai.new(settings, actions, goalObj, stateFormula, tickRewardFormula, generationRewardFormula)
    local self = setmetatable({}, ai)
    ---@type table
    self.settings = {
        alpha = settings.alpha, -- learning rate
        gamma = settings.gamma, -- discount factor
        epsilon = settings.epsilon, -- start exploration
        epsilonDecay = settings.epsilonDecay, -- exploration decay
    }

    self.trust = {} -- trust is unique for every state
    self.actions = actions -- { right = function() ... end }
    self.actionHistory = {}
    self.goalObj = goalObj

    self.stateFormula = stateFormula
    self.tickRewardFormula = tickRewardFormula
    self.generationRewardFormula = generationRewardFormula
    self.totalTickReward = 0

    self.bestTime = math.huge

    -- Local Functions
    local function getRandomActions()
        local actionNames = {}
        for name, _ in pairs(self.actions) do
            table.insert(actionNames, name)
        end

        -- Seleziona un numero casuale di azioni (da 1 a #actionNames)
        local numActions = math.random(1, #actionNames)
        local selectedActions = {}

        for _ = 1, numActions do
            local randomIndex = math.random(#actionNames)
            table.insert(selectedActions, actionNames[randomIndex])
            table.remove(actionNames, randomIndex) -- Evita duplicati
        end

        return selectedActions
    end

    local function getBestActions()
        if not self.trust[self.state] then
            return getRandomActions()
        end
    
        local bestActions = {}
        local bestValue = -math.huge
    
        for actionName, value in pairs(self.trust[self.state]) do
            if value > bestValue then
                bestActions = { actionName }
                bestValue = value
            elseif value == bestValue then
                table.insert(bestActions, actionName)
            end
        end
    
        return bestActions
    end

    local function updateActionTrust(actionEntry, reward)
        local state = actionEntry.state
        local action = actionEntry.action

        if not self.trust[state] then
            self.trust[state] = {}
            for aName, _ in pairs(self.actions) do
                self.trust[state][aName] = 0
            end
        end

        local maxFutureValue = 0
        local nextState = self.stateFormula()
        if self.trust[nextState] then
            for _, value in pairs(self.trust[nextState]) do
                maxFutureValue = math.max(maxFutureValue, value)
            end
        end
        
        if self.trust[state][action] then
            self.trust[state][action] = self.trust[state][action] + self.settings.alpha *
                (reward + self.settings.gamma * maxFutureValue - self.trust[state][action])
        end

    end

    setmetatable(self, {
        __index = function(tbl, key)
            if key == "state" then -- getter for self.state
                -- state should be distance
                return self.stateFormula()
            elseif key == "trust" then
                for actionName, _ in ipairs(self.actions) do
                    return actionName .. " - " .. self.trust[self.state][actionName]
                end
            else
                return rawget(tbl, key) or ai[key]
            end
        end
    })

    -- Global Functions
    function self.performAction(resetTotalTickReward)
        if resetTotalTickReward then
            self.totalTickReward = 0
        end

        if not self.trust[self.state] then
            self.trust[self.state] = {}
            for aName, _ in pairs(self.actions) do
                self.trust[self.state][aName] = 0
            end
        end

        local chosenActions
    if math.random() < self.settings.epsilon then
        chosenActions = getRandomActions()
    else
        chosenActions = getBestActions()
    end

    -- run all selected actions
    for _, actionName in ipairs(chosenActions) do
        local actionFunc = self.actions[actionName]
        if actionFunc then
            actionFunc()
        end
    end

    -- save actions to history
    local actionEntry = {
        state = self.state,
        actions = chosenActions
    }
    table.insert(self.actionHistory, actionEntry)

    -- mini-reward (usually related to distance)
    local reward = self.tickRewardFormula()
    updateActionTrust(actionEntry, reward)
    self.totalTickReward = self.totalTickReward + reward

    self.settings.epsilon = math.max(0.01, self.settings.epsilon * self.settings.epsilonDecay)
    end

    function self.updateTrust(ticksTaken)
        if ticksTaken < self.bestTime then
            self.bestTime = ticksTaken
        end

        -- q-learning
        local genReward = self.generationRewardFormula(ticksTaken)

        -- update trust for every action in history
        for _, action in ipairs(self.actionHistory) do
            updateActionTrust(action, genReward)
        end

        self.actionHistory = {}
        self.settings.epsilon = math.max(0.1, self.settings.epsilon * self.settings.epsilonDecay)

        return self.totalTickReward, genReward
    end

    ---@param saveFile string
    function self.saveTrustData(saveFile)
        if saveFile == nil then
            return
        end

        local file = io.open(saveFile, "w")
        if file then
            local data = {
                trust = self.trust,
                epsilon = self.settings.epsilon,
                alpha = self.settings.alpha,
                gamma = self.settings.gamma,
                epsilonDecay = self.settings.epsilonDecay
            }
            local encoded = json.encode(data)
            if encoded then
                file:write(encoded)
                file:flush() -- Forza il salvataggio immediato
                file:close()
            else
                error("Failed to encode data to JSON")
            end
        else
            error("Failed to open file for saving: " .. saveFile)
        end
    end

    ---@param saveFile string
    function self.loadTrustData(saveFile)
        if saveFile == nil then
            return
        end

        local file = io.open(saveFile, "r")
        if file then
            local data = file:read("*a")
            file:close()
            local decoded = json.decode(data) or {}

            -- Verifica che i dati letti siano validi
            if decoded.trust then
                self.trust = decoded.trust
            else
                print("Trust data not found or invalid in saved file")
                self.trust = {}
            end

            self.settings.epsilon = decoded.epsilon or 1.0
            self.settings.alpha = decoded.alpha or 0.1
            self.settings.gamma = decoded.gamma or 0.9
            self.settings.epsilonDecay = decoded.epsilonDecay or 0.95
        else
            -- Se il file non esiste, crealo con valori di default
            local newFile = io.open(saveFile, "w")
            if newFile then
                newFile:write(json.encode({
                    trust = {},
                    epsilon = 1.0,
                    alpha = 0.1,
                    gamma = 0.9,
                    epsilonDecay = 0.95
                }))
                newFile:close()
                self.trust = {}
            else
                error("Failed to create new save file: " .. saveFile)
            end
        end
    end

    function self.info()
        print("Best time: " .. self.bestTime)
        -- for i, action in ipairs(actions) do
        -- 	print("Action: " .. action .. " (Trust " .. trust[i] .. ")")
        -- end
    end
    return self
end

return ai
