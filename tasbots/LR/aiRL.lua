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
---@field actions function[]
---@field actionHistory table -- ??
---@field goalObj Object
---@field goalReachedCondition fun():boolean
---@field rewardFormula fun(ticksTaken:number):number
---@field bestTime number
---@field getDistance fun():Vector3
---@field performAction fun()
---@field updateTrust fun(timeTaken:number):number
---@field saveTrustData fun(saveFile:string|nil)
---@field loadTrustData fun(saveFile:string|nil)
---@field info fun()
local ai = {}
ai.__index = ai

---@param settings AIRLSettings
---@param actions function[]
---@param goalObj Object
function ai.new(settings, actions, goalObj, goalReachedCondition, rewardFormula)
    local self = setmetatable({}, ai)
    ---@type table
    self.settings = {}
    self.settings.alpha = settings.alpha -- learning rate
    self.settings.gamma = settings.gamma -- discount factor
    self.settings.epsilon = settings.epsilon -- start exploration
    self.settings.epsilonDecay = settings.epsilonDecay -- exploration decay

    self.trust = {} -- trust is unique for every state
    self.actions = actions -- { right = function() ... end }
    self.actionHistory = {}
    self.goalObj = goalObj

    self.goalReachedCondition = goalReachedCondition
    self.rewardFormula = rewardFormula

    self.bestTime = math.huge

    -- Local Functions
    local function getBestAction()
        if not self.trust[self.state] then
            return self.actions[math.random(#self.actions)]
        end

        local bestAction, bestValue = nil, -math.huge
        for action, value in pairs(self.trust[self.state]) do
            if value > bestValue then
                bestAction, bestValue = action, value
            end
        end
        return bestAction or self.actions[math.random(#self.actions)]
    end

    setmetatable(self, {
        __index = function(tbl, key)
            if key == "state" then -- getter for self.state
                -- state should be distance
                local dx = math.floor(mario.pos.x / 100)
                local dy = math.floor(mario.pos.y / 100)
                local dz = math.floor(mario.pos.z / 100)
                local state = tostring(dx) .. "," .. tostring(dy) .. "," .. tostring(dz)
                return state
            else
                return rawget(tbl, key) or ai[key]
            end
        end
    })

    -- Global Functions
    function self.getDistance()
        return mathDist.marioWorldDistance(self.goalObj)
    end

    function self.performAction()
        if not self.trust[self.state] then
            self.trust[self.state] = {}
            for _, action in ipairs(self.actions) do
                self.trust[self.state][action] = 0
            end
        end

        local chosenAction
        if math.random() < self.settings.epsilon then
            chosenAction = self.actions[math.random(#self.actions)]
        else
            chosenAction = getBestAction()
        end

        chosenAction()

        -- save action to history
        table.insert(self.actionHistory, {
            state = self.state,
            action = chosenAction
        })
    end

    function self.updateTrust(ticksTaken)
        if ticksTaken < self.bestTime then
            self.bestTime = ticksTaken
        end

        -- q-learning
        local reward = self.rewardFormula(ticksTaken)

        -- update trust for every action in history
        for _, entry in ipairs(self.actionHistory) do
            local state = entry.state
            local action = entry.action

            if not self.trust[state] then
                self.trust[state] = {}
                for _, a in ipairs(self.actions) do
                    self.trust[state][a] = 0
                end
            end

            local maxFutureValue = 0 -- Non consideriamo il futuro in questo caso
            self.trust[state][action] = self.trust[state][action] + self.settings.alpha *
                                            (reward + self.settings.gamma * maxFutureValue - self.trust[state][action])
        end

        self.actionHistory = {}

        self.settings.epsilon = math.max(0.1, self.settings.epsilon * self.settings.epsilonDecay)
        return reward
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
