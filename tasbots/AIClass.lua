local json = require("lib.json")

---@class AIClass
---@field saveEnabled boolean
---@field savePath string
---@field lastSave string
---@field saveData fun(self, base)
---@field loadData fun(self): any

local AIClass = {}
AIClass.__index = AIClass

local function formatData()
    return os.date("%Y/%m/%d at %H:%M:%S (y/m/d h:m:s)")
end

---@return file*
function AIClass:getFile(mode)
    mode = mode or "w"
    local file = io.open(self.savePath, mode)
    if not file then
        emu.stop("File " .. self.savePath .. " not found")
    end
    ---@cast file file*
    return file
end

function AIClass:saveData(base)
    if not self.saveEnabled then return false end

    -- saving
    local file = self:getFile("w")
    file:write(json.encode(base))
    file:close()

    self.lastSave = formatData()
    print("AI saved successfully to " .. self.savePath)
    print()
end

function AIClass:loadData()
    if not self.saveEnabled then return nil end

    -- loading
    local file = self:getFile("r")
    local content = file:read("*a")
    file:close()

    if self.lastSave then
        print("AI loaded, last save: " .. self.lastSave)
    else
        print("AI loaded for the first time")
    end
    print()
    return json.decode(content)
end

return AIClass