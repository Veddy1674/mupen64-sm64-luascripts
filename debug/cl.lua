-- A debug lua file

local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

---@type Object
local obj = nil

local timer = 0
local function start()
    obj = om.getObject(17)
end

local function update()
    timer = timer + 1
    
    if timer >= 2 then
        timer = 0
        local newObj = om.duplicateObject(obj)
        newObj.pos(mario.pos() + Vector3.new(0, 200, 0))
    end
end

emu.start(start)
emu.update(update)