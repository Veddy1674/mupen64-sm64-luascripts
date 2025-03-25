-- not a module

-- 100% range
joypad.left = {X = -128}
joypad.right = {X = 127}
joypad.down = {Y = -128}
joypad.up = {Y = 127}

joypad.setOppositeDirection = function()
    local inputs = joypad.get()
    joypad.set({X = -inputs.X, Y = -inputs.Y})
end