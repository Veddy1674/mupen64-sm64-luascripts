-- ReplayBuffer.lua

local ReplayBuffer = {}
ReplayBuffer.__index = ReplayBuffer

function ReplayBuffer.new(filepath, capacity)
    local self = setmetatable({}, ReplayBuffer)
    self.filepath = filepath
    self.capacity = capacity
    self.buffer = {}
    self.position = 1
    return self
end

function ReplayBuffer:add(s, a, r, s2, done)
    if #self.buffer < self.capacity then
        self.buffer[#self.buffer + 1] = {s, a, r, s2, done}
    else
        self.buffer[self.position] = {s, a, r, s2, done}
        self.position = (self.position % self.capacity) + 1
    end
end

function ReplayBuffer:sample(n)
    local batch = {}
    for i = 1, n do
        table.insert(batch, self.buffer[math.random(#self.buffer)])
    end
    return batch
end

function ReplayBuffer:size()
    return #self.buffer
end

return ReplayBuffer
