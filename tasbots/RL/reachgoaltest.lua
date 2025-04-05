-- Main.lua

local mario = require("lua.mario.Mario")
local camera = require("lua.mario.Camera")
local om = require("lua.object.ObjectManager")

local goalObj = om.getObjects()[43]
local marioObj = mario.getObj()

local function update()
    ---@cast goalObj Object
    ---@cast marioObj Object
    
    local yaw = camera.yawRad()
    local distance = marioObj.distanceXZFrom(goalObj)
    local absDirection = distance.normalize()
    local relDirection = Vector3.new(
        absDirection.x * math.cos(yaw) - absDirection.z * math.sin(yaw),
        0,
        absDirection.x * math.sin(yaw) + absDirection.z * math.cos(yaw)
    )

    local bestX, bestZ = relDirection.x * 127 // 1, relDirection.z * -127 // 1

    joypad.set({X = bestX, Y = bestZ})
    print(string.format("Direction: (%d, %d) - %.2f units away", bestX, bestZ, distance.distance(Vector3.new(0, 0, 0))))

    if marioObj.overlapsWith(goalObj) then
        emu.stop("test end")
    end
end

emu.update(update)