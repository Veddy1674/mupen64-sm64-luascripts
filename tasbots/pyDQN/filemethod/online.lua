-- online.lua
-- offline method idea:
-- 1. lua does random actions
-- 2. lua ends record and writes actions, rewards and the states to a file
-- 3. python reads the file and trains the model
-- 4. python writes the model to a file (it needs to be intepreted by lua!!)
-- 5. lua reads the model and uses it to play the game less randomically

-- online method idea: (current)
-- 1. lua does a random action
-- 2. lua pauses the game, writes the action, previous state, current state and reward to a file
-- 3. python reads the file and rewards the model
-- 4. python writes into a file what next action to do
-- 5. lua does the action python says instead of random action

require("lua.misc.Utils")
local camera = require("lua.mario.Camera")
local mario = require("lua.mario.Mario")
local marioObj = mario.getObj() or error()
local om = require("lua.object.ObjectManager")

local st = "lua/tasbots/pyDQN/filemethod/getstar.st1"
local inputPath = "lua/tasbots/pyDQN/filemethod/input.txt"
local outputPath = "lua/tasbots/pyDQN/filemethod/output.txt"
local infoPath = "lua/tasbots/pyDQN/filemethod/info.csv"

local pauseWhenEnd = false -- pause the game when the episode ends (both success and failure)

local timelimit = 45
local frame = 0
local prevAction = {0,0,0,0}
local star = om.getObject(100)

local function reset()
    savestate.loadfile(st)
end

local function getFrameInfo()
    local cameraYaw = camera.yawRad()
    return
        tostring(mario.pos().distance(star.pos()) / 1300) .. "," ..
        tostring(mario.speed().h / 33) .. "," ..
        tostring(mario.yawInfo().facing() / 65535) .. "," ..
        tostring(math.sin(cameraYaw)) .. "," .. tostring(math.cos(cameraYaw))
end

local function goodAction()
    return star.overlapsWith(marioObj)
end

local function badAction()
    return mario.pos().distance(star.pos()) > 1200 or frame >= timelimit
end

---@type number
local prevDist
local function getReward()
    local dist = mario.pos().distance(star.pos())
    local reward = ((prevDist - dist) / 1300) * 5
    prevDist = dist
    return reward
end

local function parseAction(str)
    local t = {}
    for v in string.gmatch(str, "[^,]+") do
        table.insert(t, tonumber(v))
    end
    return t
end

local validActions = {
    {0,0,0,0},
    {0,0,0,1},
    {0,0,1,0},
    {0,1,0,0},
    {0,1,0,1},
    {0,1,1,0},
    {1,0,0,0},
    {1,0,0,1},
    {1,0,1,0},
}

-- Funzione per verificare se azione è valida
local function isValidAction(action)
    for _, valid in ipairs(validActions) do
        local match = true
        for i=1,4 do
            if action[i] ~= valid[i] then
                match = false
                break
            end
        end
        if match then
            return true
        end
    end
    return false
end

-- Interpretazione dell'azione in input joypad.set
local function interpretAction(action)
    -- Azione deve essere valida, altrimenti nessun input
    if not action or not isValidAction(action) then
        return joypad.none
    end

    local buttons = {}
    if action[1] == 1 then buttons.Y = 127 end
    if action[2] == 1 then buttons.Y = -127 end
    if action[3] == 1 then buttons.X = 127 end
    if action[4] == 1 then buttons.X = -127 end

    return buttons
end

local function readAction()
    local f = io.open(outputPath, "r") or error()
    local content = f:read("*a")
    f:close()
    if content == "" then return nil end

    local fclear = io.open(outputPath, "w") or error()
    fclear:close()

    return parseAction(content)
end

local function writeData(frameInfo, reward, action, terminal)
    local f = io.open(inputPath, "a") or error()
    local line = tostring(reward) .. "," .. table.concat(action, ",") .. "," .. frameInfo
    if terminal then
        line = line .. ",1"
    else
        line = line .. ",0"
    end
    f:write(line .. "\n")
    f:close()
end

emu.start(function()
    reset()
    joypad.set({})
    prevDist = mario.pos().distance(star.pos())
end)

local epoch = 0
local avgReward = 0

emu.update(function()
    emu.pause(true)

    local frameInfo = getFrameInfo()
    local r = getReward()
    if joypad.get().up then print("Reward: " .. r) end
    avgReward = avgReward + r

    local good, bad = goodAction(), badAction()
    if prevAction then
        local terminal = good or bad
        writeData(frameInfo, r, prevAction, terminal)
    end

    local i, action = 0, nil
    repeat
        action = readAction()
        emu.pause(false)
        i = i + 1
        if i > 5e3 then
            emu.stop("Timeout (5e3 CPU cycles)")
            return
        end
    until action
    ---@cast action table

    joypad.set(interpretAction(action))
    prevAction = action
    frame = frame + 1

    if good or bad then
        local f = io.open(infoPath, "a") or error()
        f:write(string.format(
            "Episode:%d,AvgReward:%.2f,Survived:%d\n",
            epoch, avgReward, frame
        ))
        f:close()

        avgReward = 0

        print(tostring(epoch) .. " -> " .. (good and "SUCCESS!" or "FAILURE!"))
        reset()
        frame = 0
        epoch = epoch + 1
        if pauseWhenEnd then
            emu.pause(true)
        end
    end
end)

emu.stopped(function()
end)