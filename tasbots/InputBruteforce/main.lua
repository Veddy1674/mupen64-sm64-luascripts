-- main.lua

require("lua.tasbots.InputBruteforce.shared")

local json = require("lib.json")
local actionInterpreter = require("lua.tasbots.InputBruteforce.actionInterpreter")

---@type string[]
local goodEndings = {}

local function save2(parallelism, failcount, goodcount)
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

local function save(failcount, goodcount)

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
        return
    end

    -- MULTIPLE INSTANCES
    local text = string.split(instanceContent, ",")
    local instance, _maxInstance = tonumber(text[1] + 1), tonumber(text[2])

    instanceInfo:close()
    instanceInfo = io.open(instanceCountFile, "w")
    if not instanceInfo then emu.stop() return end -- never happens, but it makes the intellisense happy
    instanceInfo:write(instance .. "," .. _maxInstance)
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

    elseif instance == _maxInstance then
        dataToSave = dataToSave:sub(2)

    else -- MIDDLE INSTANCE (when maxInstance >= 3)
        dataToSave = dataToSave:sub(2):gsub("]$", ",")

    end

    goodEndingsFile:write(goodEndingContent .. dataToSave)
    goodEndingsFile:close()
    save2(false, failcount, goodcount)
end

-- local function start()
reset()
---@diagnostic disable-next-line
_emu.set_ff(true)
-- end

local framelist = {}
local failsCount = 0

local db = false
local function update()
    if not db then
        db = true
        init()
        return
    end
    if doingBadAction(#framelist) then
        failsCount = failsCount + 1
        reset()
        framelist = {}
        return
    elseif doingGoodAction() then
        printf("Found a good ending (%d frames)", #framelist)
        table.insert(goodEndings, framelist)
        framelist = {}
        reset()
        return
    end

    local action = actionInterpreter.randomActions()
    table.insert(framelist, action)
    joypad.set(actionInterpreter.toInputs(action))
end

-- emu.start(start)
emu.update(update)
emu.stopped(function()
    reset()
    save(failsCount, #goodEndings)
    ---@diagnostic disable-next-line
    _emu.set_ff(false)
end)
