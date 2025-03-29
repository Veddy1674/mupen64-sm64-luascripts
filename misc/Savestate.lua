-- not a module

-- Stops script execution (instantly)
stop = function(reason)
    error(reason or "\"stop()\" invoked.")
end

---@class Savestate
---@field savefile fun(filename:string) Saves the current state to a file
---@field loadfile fun(filename:string) Loads a state from a file
local Savestate = {}

---@type Savestate
savestate = Savestate

-- Alias per accedere a _G.savestate
local SAVESTATE = _G.savestate

-- Metodo pubblico: savefile
function savestate.savefile(filename)
    if type(filename) ~= "string" then
        error("Expected a string for 'filename', got " .. type(filename))
    end
    ---@diagnostic disable-next-line: undefined-field
    SAVESTATE.save(filename)
end

-- Metodo pubblico: loadfile
function savestate.loadfile(filename)
    if type(filename) ~= "string" then
        error("Expected a string for 'filename', got " .. type(filename))
    end
    ---@diagnostic disable-next-line: undefined-field
    SAVESTATE.load(filename)
end