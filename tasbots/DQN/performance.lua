-- performance.lua - a module to apply optimizations to a DQN agent

-- Use example:
-- with preset: PerformanceConfig:applyConfig("fastest", marioObj, om.getObjects())
--- with custom config: PerformanceConfig:applyConfig({ -- EVERY PARAMETER IS MANDATORY
--     excludeObjects = {coin},
--     disableMusic = true,
--     disablePrints = false,
--     invisibleObjects = true
-- }, marioObj, om.getObjects())


require("lua.misc.Utils")

local pc = {} -- module, not a class!

---@class PerformanceConfig
---@field disableMusic boolean -- disable music and sound effects
---@field disablePrints boolean -- disable prints (print and printf) completely
---@field invisibleObjects boolean
pc.config = {}

-- fastest: no music, no prints, invisible objects...
-- debug: no music, yes prints, visible objects...
-- fastestfixed: like "fastest" but objects' physics disabled (useful when mario doesn't move with joypad.set)
---@param config PerformanceConfig|"fastest"|"debug"|"fastestfixed"
function pc.setConfig(config)
    if type(config) == "string" then
        if config == "fastest" or config == "fastestfixed" then -- presets
            config = {
                -- note: for some reason disabling music makes the fps spike from ~600 to ~1100+ fps
                disableMusic = true,
                disablePrints = true,
                invisibleObjects = true,
            }
        elseif config == "debug" then
            config = {
                disableMusic = false,
                disablePrints = false,
                invisibleObjects = false,
            }
        end
    end
    ---@cast config PerformanceConfig
    pc.config = config
end

---@param marioObj Object
---@param objectList Object[] -- must be memory ordered
---@param excludeObjects Object[]|nil -- objects exclude from unloading (leave to nil to disable)
function pc.applyConfig(marioObj, objectList, excludeObjects)

    local config = pc.config -- avoid accidental modifications

    if excludeObjects ~= nil or config.invisibleObjects then
        for i, obj in ipairs(objectList) do
            if config == "fastestfixed" or (excludeObjects ~= nil and (not table.any(excludeObjects, function(o) return i == o.slotIndex end))) then
                obj.unload()
            end
            if config.invisibleObjects then
                obj.graphInfo().visible(false)
                obj.graphics(0)
            end
        end
    end
    if config.invisibleObjects then
        -- make mario invisible too
        local i = marioObj.graphInfo()
        i.visible(false)
        i.active(false) -- it does not affect mario's movement at all
        marioObj.graphics(0)
    end

    if config.disableMusic then
        -- usa rom only, you can find other offsets here: https://github.com/SM64-TAS-ABC/STROOP/blob/dev/STROOP/Config/MiscData.xml#L28
        memory.accessWithMask(0x80222618, 0x20, config.disableMusic) -- boolean is inverted!
    end

    if config.disablePrints then
        printf = function() end
        print = function() end
    end
end

return pc