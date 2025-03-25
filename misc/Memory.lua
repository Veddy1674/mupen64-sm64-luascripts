-- not a module

types = {
    FLOAT = 1,
    UINT = 2,
    INT = 3,
    BYTE = 4,
    SBYTE = 5,
    SHORT = 6,
    USHORT = 7,
}

memory.access = function(address, vartype, value)
    if (vartype == types.FLOAT) then
        if value then
            memory.writefloat(address, value)
        end
		return memory.readfloat(address)
    elseif (vartype == types.UINT) then
        if value then
            memory.writedword(address, value)
        end
		return memory.readdword(address)
    elseif (vartype == types.INT) then
        if value then
            memory.writedword(address, value)
        end
		return memory.readdwordsigned(address)
    elseif (vartype == types.BYTE) then
        if value then
            memory.writebyte(address, value)
        end
		return memory.readbyte(address)
	elseif (vartype == types.SBYTE) then
        if value then
            memory.writebyte(address, value)
        end
		return memory.readbytesigned(address)
    elseif (vartype == types.SHORT) then
        if value then
            memory.writeword(address, value)
        end
		return memory.readwordsigned(address)
	elseif (vartype == types.USHORT) then
        if value then
            memory.writeword(address, value)
        end
		return memory.readword(address)
	end
	-- type invalid
	print("Invalid memory type \"" .. vartype .. "\". " .. "(" .. (value and "write" or "read") .. ")")
	stop()
	return nil
end