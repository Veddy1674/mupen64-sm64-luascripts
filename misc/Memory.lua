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

    self.access = function(address, vartype, value)
        ---@diagnostic disable: need-check-nil, undefined-field
        
        if (vartype == FLOAT) then
            if value then
                _memory.writefloat(address, value)
            end
            return _memory.readfloat(address)
        elseif (vartype == UINT) then
            if value then
                _memory.writedword(address, value)
            end
            return _memory.readdword(address)
        elseif (vartype == INT) then
            if value then
                _memory.writedword(address, value)
            end
            return _memory.readdwordsigned(address)
        elseif (vartype == BYTE) then
            if value then
                _memory.writebyte(address, value)
            end
            return _memory.readbyte(address)
        elseif (vartype == SBYTE) then
            if value then
                _memory.writebyte(address, value)
            end
            return _memory.readbytesigned(address)
        elseif (vartype == SHORT) then
            if value then
                _memory.writeword(address, value)
            end
            return _memory.readwordsigned(address)
        elseif (vartype == USHORT) then
            if value then
                _memory.writeword(address, value)
            end
            return _memory.readword(address)
        end
    
        -- type invalid
        stop("Invalid memory type \"" .. vartype .. "\". " .. "(" .. (value and "write" or "read") .. ")")
        ---@type number
        return nil
        ---@diagnostic enable: need-check-nil, undefined-field
    end

    return self
end

---@type Memory
memory = Memory.new()