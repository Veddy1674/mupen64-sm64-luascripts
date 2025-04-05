require("lua.misc.Utils")

---@alias ActionMap table<string, Inputs>

---@class AIState
---@field identifier string
---@field startEpsilon number
---@field aiSettings AIRLSettings
---@field trust table<string, number>
---@field getBestActionName fun(conditionFunc?:fun(actionName:string):boolean):string -- actionName
---@field updateTrustFor fun(actionName:string, reward:number)
---@field info fun()
local AIState = {}
AIState.__index = AIState

---@param identifier string
---@param actions ActionMap -- temp
---@param aiSettings AIRLSettings
---@return AIState
function AIState.new(identifier, actions, aiSettings)
    local self = setmetatable({}, AIState)
    self.identifier = identifier
    self.aiSettings = aiSettings
    self.startEpsilon = self.aiSettings.base_epsilon -- saved because of save/load system
    -- each state gets optimized on its own

    self.trust = {}
    -- init trust
    for actionName, _ in pairs(actions) do
        self.trust[actionName] = 0
    end
    
    -- Only returns one best action
    self.getBestActionName = function(conditionFunc)
        if self.aiSettings.base_epsilon > emu.rand() then
            -- random action
            if conditionFunc == nil then return table.random(self.trust) end

            local randAction = nil
            repeat
                randAction = table.random(self.trust) -- could forever loop!
            until conditionFunc(randAction)
            return randAction
        end
        -- best action
        ---@type table<string, number>
        local sortedActions = {} -- sorted by trust descending: e.g { ["A"] = 10, ["B"] = 5 }
        -- copying trust into sortedActions:
        for actionName, trust in pairs(self.trust) do
            table.insert(sortedActions, {action = actionName, trust = trust})
        end
        table.sort(sortedActions, function(a, b) return a.trust > b.trust end)
        
        if conditionFunc == nil then return sortedActions[1] end

        local bestActionName = nil
        for i = 1, #sortedActions do
            bestActionName = sortedActions[i].action
            if conditionFunc(bestActionName) then
                return bestActionName
            end
        end
        emu.stop("No action found (Everything got excluded)")
        ---@type string
        return nil
    end

    -- Updates trust for a specific action with a specific reward
    self.updateTrustFor = function(actionName, reward)
        -- Every action is initialized in trust {}, so self.trust[actionName] always exists if actions arg contains actionName
        self.trust[actionName] = self.trust[actionName] + self.aiSettings.alpha * (
            reward + self.aiSettings.gamma * 0 - self.trust[actionName]
        )

        -- epsilon multiplier can be like:
        -- x 1.01 makes 0.99 become 0.9999
        -- x 1.004 makes 0.99 become 0.99396 (~3frames)
        -- x 1.007 makes 0.99 become 0.99693 (first state's epsilon in ~27th generation: 0.62)
        self.aiSettings.base_epsilon =
            math.max(0.1, self.aiSettings.base_epsilon * self.aiSettings.epsilonDecay * 1.0099)
    end

    -- Prints info about state's epsilon and trust
    self.info = function()
        print("State: [" .. self.identifier .. "]")
        print(string.format("Epsilon: %.2f / %.2f (%.2f decay)", self.aiSettings.base_epsilon, self.startEpsilon, self.aiSettings.epsilonDecay))
        print("Trust = {")
        for actionName, trust in pairs(self.trust) do
            print("    " .. actionName .. ": " .. trust)
        end
        print("}")
        print()
    end

    return self
end

return AIState