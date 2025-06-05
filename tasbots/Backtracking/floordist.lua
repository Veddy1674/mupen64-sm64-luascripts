local mario = require("lua.mario.Mario")

local obj = mario.getObj()

emu.update(function()
    local floorTri = mario.getFloorTriangle().vertices()
    local midTri = floorTri.mid().set("y", 0).set("z", 0)
    local midMario = mario.pos().set("y", 0).set("z", 0)
    local dist = midTri.distance(midMario)
    printf("Distance: %.2f", dist)
end)