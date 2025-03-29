-- A debug lua file

local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")

---@type Object
local obj = nil

local function start()
    obj = om.getObjects()[18]
end

local function update()
    local marioObj = mario.getObj()
    if not marioObj then print("no mario") return end

    local marioOverlaps = marioObj.overlapsWith(obj)
    print("Mario overlaps with OBJ: " .. (marioOverlaps and "Yes" or "No"))

    if marioOverlaps then
        emu.stop()
    end
end

emu.start(start)
emu.update(update)