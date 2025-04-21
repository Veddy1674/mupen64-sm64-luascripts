-- AIState.lua

require("lua.misc.Utils")
require("lua.lib.aiutils")
require("lua.tasbots.InputBruteforce.shared")
local actionInterpreter = require("tasbots.RL.actionInterpreter")

---@class AIState
---@field identifier string
---@field epsilon number
---@field aiSettings AIRLSettings
---@field trust table<string, number>
---@field reward fun(action:string, reward:number)
---@field getBestAction fun():string
---@field info fun()
local AIState = {}
AIState.__index = AIState

---@param identifier string
---@param aiSettings AIRLSettings
---@return AIState
function AIState.new(identifier, aiSettings)
    local self = setmetatable({}, AIState)
    self.identifier = identifier
    self.aiSettings = aiSettings
    self.epsilon = self.aiSettings.base_epsilon
    self.trust = {}

    self.reward = function(action, reward)
        local prev = self.trust[action] or 0
        self.trust[action] = prev + self.aiSettings.alpha * (reward - prev)

        self.epsilon = math.max(0.1, self.epsilon * self.aiSettings.epsilonDecay * 1.0099)
    end

    self.getBestAction = function()
        if math.random() < self.epsilon or next(self.trust) == nil then
            local newAction = actionInterpreter.randomActions()
            -- print(newAction)
            if not self.trust[newAction] then -- update trust
                self.trust[newAction] = 0
            end
            return newAction
        end
        return tostring(argmax(self.trust))
    end

    self.info = function()
        printf("State: [%s]", self.identifier)
        printf("Epsilon: %.2f / %.2f (%.2f decay)",
            self.aiSettings.base_epsilon, self.epsilon, self.aiSettings.epsilonDecay
        )
        printf("Trust = {\n")
        for action, trust in pairs(self.trust) do
            print("    " .. action .. ": " .. trust .. "\n")
        end
        printf("}\n")
    end

    return self
end

return AIState
