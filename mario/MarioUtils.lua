-- MarioUtils.lua

local module = {}

function module.byte_property(address, offset, mask, value)
    local p = address + offset
    if value ~= nil then
        memory.writebyte(p, value and mask or 0x00)
    end
    return (memory.readbyte(p) & mask) == mask
end

return module