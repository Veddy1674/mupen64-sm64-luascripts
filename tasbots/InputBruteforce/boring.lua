-- boring.lua

require("lua.tasbots.InputBruteforce.shared")
local json = require("lib.json")

_instance = -1
_maxInstance = -1
---@type string[]
goodEndings = {}

function save2(parallelism, failcount, goodcount)
    -- saving more info
    local file = io.open(infoFile, "r")
    if not file then emu.stop() return end

    if parallelism then
        local info = json.decode(file:read("*a"))
        failcount = failcount + info.fails
        goodcount = goodcount + info.goods
    end
    file:close()
    file = io.open(infoFile, "w")
    if not file then emu.stop() return end -- never happens, but it makes the intellisense happy
    file:write(json.encode({fails = failcount, goods = goodcount, total = (failcount + goodcount)}))
    file:close()
end

function save(failcount, goodcount)

    local instanceInfo = io.open(instanceCountFile, "r")
    if not instanceInfo then emu.stop() return end

    ---@type file*?
    local goodEndingsFile = nil

    local instanceContent = instanceInfo:read("*a"):gsub("%s+", "") -- gsub to clean up
    if instanceContent == "0,1" then
        -- SINGLE INSTANCE
        goodEndingsFile = io.open(goodEndingFile, "w")
        if not goodEndingsFile then emu.stop() return end
        goodEndingsFile:write(json.encode(goodEndings))
        goodEndingsFile:close()
        instanceInfo:close()
        save2(true, failcount, goodcount)
        _instance = 1 -- debugging purposes only
        _maxInstance = 1 -- debugging purposes only
        return
    end

    -- MULTIPLE INSTANCES
    local text = string.split(instanceContent, ",")
    local instance, maxInstance = tonumber(text[1] + 1), tonumber(text[2])
    _instance = instance -- debugging purposes only
    _maxInstance = maxInstance -- debugging purposes only

    instanceInfo:close()
    instanceInfo = io.open(instanceCountFile, "w")
    if not instanceInfo then emu.stop() return end -- never happens, but it makes the intellisense happy
    instanceInfo:write(instance .. "," .. maxInstance)
    instanceInfo:close()

    -- if first instance then replace ] with ,
    -- if last instance then remove [
    -- if middle instance then remove [ and replace ] with ,
    local dataToSave = json.encode(goodEndings)

    goodEndingsFile = io.open(goodEndingFile, "r")
    if not goodEndingsFile then emu.stop() return end
    local goodEndingContent = goodEndingsFile:read("*a")
    goodEndingsFile:close()

    goodEndingsFile = io.open(goodEndingFile, "w")
    if not goodEndingsFile then emu.stop() return end -- never happens, but it makes the intellisense happy

    if instance == 1 then
        dataToSave = dataToSave:gsub("]$", ",")

    elseif instance == maxInstance then
        dataToSave = dataToSave:sub(2)

    else -- MIDDLE INSTANCE (when maxInstance >= 3)
        dataToSave = dataToSave:sub(2):gsub("]$", ",")

    end

    goodEndingsFile:write(goodEndingContent .. dataToSave)
    goodEndingsFile:close()
    save2(false, failcount, goodcount)
end

