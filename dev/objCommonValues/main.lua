
--[[
    This script allows you to save common data of an object
    For example a coin: behavior script, graphics, model and other info are saved.
    When you need to spawn a coin, the script looks for a saved file with coins' common data,
    and spawns the coin for you, a good alternative to om.duplicateObject(...), so that you can
    generate any object anytime and anywhere, regardless if there is that object in the area
]]

-- Currently implemented in ObjectManager#spawnObject(...)

local om = require("lua.object.ObjectManager")
local mario = require("lua.mario.Mario")
local json = require("lib.json")

local obj = om.getObjects()[53]
local saveFile = "lua/dev/objCommonValues/coin.json"

local function spawnObject(file)
    local file = io.open(saveFile, "r")
    if not file then emu.stop("file " .. saveFile .. " not found") end

    ---@cast file file*
    local data = json.decode(file:read("*a"))
    file:close()

    local newObj = om.firstUnloadedCell()
    newObj.clear()

    for offset = 0, 0x260-0x4, 0x4 do
        if not table.any(importantAddressOffsets, function(o) return o == offset end) then
            local value = data[tostring(offset)]
            memory.access(newObj.base + offset, UINT, value)
        end
    end

    newObj.parent(newObj)

    newObj.pos(Vector3.new())
    newObj.speed(Speed4.new())

    newObj.revive()
    return newObj
end

local function saveObject(saveObj)
    local values = {}
    for offset = 0, 0x260-0x4, 0x4 do
        if not table.any(importantAddressOffsets, function(o) return o == offset end) then
            values[tostring(offset)] = memory.access(saveObj.base + offset, UINT)
        end
    end

    local file = io.open(saveFile, "w")
    if file then
        file:write(json.encode(values))
        file:close()
        print("saved to " .. saveFile .. " (" .. saveObj.name() .. ")")
    else
        emu.stop("file error")
    end
end

-- saveObject(obj)
local o = spawnObject(saveFile)
o.pos(mario.pos() + Vector3.new(0, 250, 0))