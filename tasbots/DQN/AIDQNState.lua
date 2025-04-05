-- AIDQNState.lua

---@class AIDQNState
---@field identifier string
---@field trust table<string, number>
---@field getBestAction fun():string
local AIDQNState = {}
AIDQNState.__index = AIDQNState

---@param identifier string
---@param actions table<string, any>
---@return AIDQNState
function AIDQNState.new(identifier, actions)
    local self = setmetatable({}, AIDQNState)
    self.identifier = identifier
    self.trust = {}
    for action, _ in pairs(actions) do
        self.trust[action] = 0
    end

    function self.getBestAction()
        local bestAction, maxTrust = nil, -math.huge
        for action, trust in pairs(self.trust) do
            if trust > maxTrust then
                bestAction, maxTrust = action, trust
            end
        end
        ---@cast bestAction string
        return bestAction
    end

    return self
end

return AIDQNState
