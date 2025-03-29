-- A debug lua file

local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

---@type Object
local obj = nil

local function start()
    obj = om.getObjects()[200]
    obj.setActive(true) -- ok perfetto ma ma ci sono altre operazioni da fare
    -- local o = om.duplicate(obj)
    -- print("Duplicated ID: " .. o.slotIndex)
end

local function update()

end

emu.start(start)
emu.update(update)