-- AIState.lua

require("lua.misc.Utils")
require("lib.aiutils")

---@class AIState
---@field identifier string -- e.g [10,0,10,15] being mario's position and h speed
---@field epsilon number -- each state gets optimized on its own
---@field aiSettings AIRLSettings
---@field trust table<string, number>
---@field reward fun(action:string, reward:number)
---@field getBestAction fun():string
---@field info fun()
local AIState = {}
AIState.__index = AIState

---@param identifier string
---@param actions string[] -- temp
---@param aiSettings AIRLSettings
---@return AIState
function AIState.new(identifier, actions, aiSettings)
    local self = setmetatable({}, AIState)
    self.identifier = identifier
    self.aiSettings = aiSettings
    self.epsilon = self.aiSettings.base_epsilon

    self.trust = {}
    -- init trust
    for _, action in pairs(actions) do
        self.trust[action] = 0--math.randomforcefloat(-0.1, 0.1)
    end

    -- Updates trust for a specific action with a specific reward
    self.reward = function(action, reward)
        self.trust[action] = self.trust[action]
            + (self.aiSettings.alpha) * (reward - self.trust[action])

        
        self.epsilon =
            math.max(0.1, self.epsilon * self.aiSettings.epsilonDecay * 1.0099)
    end

    self.getBestAction = function()
        if math.random() < self.epsilon then
            return table.randomKey(self.trust)
        end
        return tostring(argmax(self.trust))
    end

    self.info = function()
        printf("State: [" .. self.identifier .. "]")
        printf("Epsilon: %.2f / %.2f (%.2f decay)",
            self.aiSettings.base_epsilon, self.epsilon, self.aiSettings.epsilonDecay
        )
        printf("Trust = {\n")
        for action, trust in pairs(self.trust) do
            printf("    " .. action .. ": " .. trust .. "\n")
        end
        printf("}\n")
    end

    return self
end

return AIState
