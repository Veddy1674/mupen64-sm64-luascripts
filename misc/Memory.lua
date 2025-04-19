-- not a module

-- Types
FLOAT = "FLOAT"
UINT = "UINT"
INT = "INT"
BYTE = "BYTE"
SBYTE = "SBYTE"
SHORT = "SHORT"
USHORT = "USHORT"

local Memory = {}
Memory.__index = Memory

---@type nil
_memory = _G.memory

---@private
---@return Memory
function Memory.new()
    ---@class Memory
    ---@field access fun(address: number, vartype: "FLOAT"|"UINT"|"INT"|"BYTE"|"SBYTE"|"SHORT"|"USHORT", value?: number): number
    local self = setmetatable({}, Memory)

    ---@param address number
    ---@param vartype "FLOAT"|"UINT"|"INT"|"BYTE"|"SBYTE"|"SHORT"|"USHORT"
    ---@param value? number
    ---@return number
    self.access = function(address, vartype, value)
        ---@diagnostic disable: need-check-nil, undefined-field
        
        local operations = {
            [FLOAT] = {write = _memory.writefloat, read = _memory.readfloat},
            [UINT] = {write = _memory.writedword, read = _memory.readdword},
            [INT] = {write = _memory.writedword, read = _memory.readdwordsigned},
            [BYTE] = {write = _memory.writebyte, read = _memory.readbyte},
            [SBYTE] = {write = _memory.writebyte, read = _memory.readbytesigned},
            [SHORT] = {write = _memory.writeword, read = _memory.readwordsigned},
            [USHORT] = {write = _memory.writeword, read = _memory.readword}
        }
    
        local operation = operations[vartype]
        if operation then
            if value then
                operation.write(address, value)
            end
            return operation.read(address)
        end
    
        -- type invalid
        stop("Invalid memory type \"" .. vartype .. "\". " .. "(" .. (value and "write" or "read") .. ")")
        ---@type number
        return nil
        ---@diagnostic enable: need-check-nil, undefined-field
    end

    ---@param address number
    ---@param mask number
    ---@param value? boolean
    ---@return boolean
    self.accessWithMask = function(address, mask, value)
        ---@diagnostic disable: need-check-nil, undefined-field
        
        local v = _memory.readbyte(address)
        if value ~= nil then
            v = v | mask
            _memory.writebyte(address, v)
        end
        
        return (v & mask) == mask
        
        ---@diagnostic enable: need-check-nil, undefined-field
    end

    return self
end

---@type Memory
memory = Memory.new()