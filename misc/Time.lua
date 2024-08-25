-- Time.lua

local waitQueue = {}

local function processWaitQueue()
    local currentFrame = emu.framecount()
    for i = #waitQueue, 1, -1 do
        local waitInfo = waitQueue[i]
        if currentFrame - waitInfo.startFrame >= waitInfo.frames then
            table.remove(waitQueue, i)
            if waitInfo.callback then
                waitInfo.callback()
            end
        end
    end
end

local function _update()
    processWaitQueue()
end

local oldAtInput = emu.atinput
emu.atinput = function(callback) -- override emu.atinput
    local function wrapper()
        _update()
        callback()
    end
    oldAtInput(wrapper)
end

-- public
function wait(callback, frames)
    table.insert(waitQueue, {
        startFrame = emu.framecount(),
        frames = frames,
        callback = callback
    })
end