-- ReplayBuffer.lua

---@class ReplayBuffer
---@field buffer table
---@field capacity number
---@field add fun(state:table, action:number, reward:number, next_state:table, done:boolean)
---@field getBatch fun(batch_size:number):table
local ReplayBuffer = {}
ReplayBuffer.__index = ReplayBuffer

---@param capacity number
---@return ReplayBuffer
function ReplayBuffer.new(capacity)
    local self = setmetatable({}, ReplayBuffer)
    self.buffer = {}
    self.capacity = capacity

    ---@param state table
    ---@param action number
    ---@param reward number
    ---@param next_state table
    ---@param done boolean
    function self.add(state, action, reward, next_state, done)
        if #self.buffer >= self.capacity then
            table.remove(self.buffer, 1) -- remove oldest entry
        end
        table.insert(self.buffer, {state, action, reward, next_state, done})
    end

    ---@param batch_size number
    ---@return table
    function self.getBatch(batch_size)
        local batch = {}
        for i = 1, batch_size do
            local index = math.random(#self.buffer)
            table.insert(batch, self.buffer[index])
        end
        return batch
    end

    return self
end

return ReplayBuffer
