-- ObjectList.lua

local function new(bs, g, m, group, other) -- other is a table
	local list = {
        bhvscript = bs or 0x0,
        graphics = g or 0x0,
        model = m or 0x0,
		group = group or "None"
    } -- other items are purposely set in a separate list
	if other then
		local more = {}
		for _, p in pairs(other) do table.insert(more, p) end -- list in a list in a list of a list
		list.other = more
	end
	return list
end

local function custom(a, b, c)
	return {
		offset = a,
		default = b, -- value
		vartype = c
	}
end

-- ["Name"], Behaviour Script, Graphics, Group, Model
return {
    ["Unknown"] = new(),
	["Mario"] = new(0x800EE040, 0x800F0860),
	["Standard Door"] = new(0x800EBC8C, 0x8018E8A8, 0x800D0E28, "Door"),
	["Wooden Door"] = new(0x800EBC8C, 0x8018ECD8, 0x800D0E28, "Door"),
	["0 Star Door"] = new(0x800EBC8C, 0x8018EDE4, 0x800D0E28, "Door"),
	["1 Star Door"] = new(0x800EBC8C, 0x8018EF20, 0x800D0E28, "Door"),
	["3 Star Door"] = new(0x800EBC8C, 0x8018F05C, 0x800D0E28, "Door"),
	["Sign"] = new(0x800EE460, 0x800F8C4C, 0x800E1D30),
	["Coin"] = new(0x800EBA9C, 0x800F8AA4, 0x0, "Coin", {
		disapbhv = custom(0x1D4, 0x800EBAB4, "uint"),
		shadow = custom(0x16, 0x9370, "byte"),
		value = custom(0x180, 1, "int"),
	}),
	["Red Coin"] = new(0x800EF02C, 0x800F9C24, 0x0, "Coin", {
		value = custom(0x180, 2, "int"),
	}),
	["Blue Coin"] = new(0x800ED708, 0x800F9464, 0x0, "Coin", {
		value = custom(0x180, 5, "int"),
	}),
	["Walk Dust"] = new(0x800ED680, 0x800F8544, 0x0, "Dust"),
	["Ground Dust"] = new(0x800EB95C, 0x800F9298, 0x0, "Dust"),
	["Star Dust"] = new(0x800EBBF8, 0x800FA108, 0x0, "Dust"),
	["Bowser"] = new(0x800EC9D0, 0x80181360, 0x0, "Bowser") -- bowser 1 ?
}