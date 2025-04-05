-- -- Main.lua (DQN Version)
-- local aiFactory = require("lua.tasbots.DQN.AIDQN")
-- local om = require("lua.object.ObjectManager")
-- local mario = require("lua.mario.Mario")

-- local savePath = "lua/tasbots/DQN/example.st1"

-- local goalObj = om.getObjects()[43]
-- local marioObj = mario.getObj()
-- ---@cast marioObj Object

-- local lastSpeed = 0

-- ---@type AIDQN
-- local ai = aiFactory.new(4, 16, 4, "lua/tasbots/DQN/replay_buffer.json") -- input, hidden, output

-- local function stateFormula()
--     return {
--         mario.pos().x / 70,
--         mario.pos().y / 70,
--         mario.pos().z / 70,
--         mario.speed().h
--     }
-- end

-- local function rewardFormula()
--     return mario.isAction(marioAction.walking) and 10 or -10
-- end

-- local function reset()
--     joypad.set({})
--     savestate.loadfile(savePath)
-- end

-- local function start()
--     savestate.savefile(savePath)
-- end

-- local function update()
--     local state = stateFormula()
--     local action = ai.chooseAction(state)
    
--     local chosenActions = {}
--     if action == 1 then chosenActions = {A = true} 
--     elseif action == 2 then chosenActions = {B = true}
--     elseif action == 3 then chosenActions = {A = true, B = true}
--     end

--     joypad.set(chosenActions)

--     local reward = rewardFormula()
--     local next_state = stateFormula()
--     local done = marioObj.overlapsWith(goalObj)

--     ai.step(state, action, reward, next_state, done)

--     if done then
--         ai.saveTo()
--         ai.epsilon = math.max(0.1, ai.epsilon * ai.epsilonDecay)
--         reset()
--     end

--     -- Debugging
--     if joypad.contains("up") then
--         print("State:", table.concat(state, ", "))
--     end
-- end

-- emu.start(start)
-- emu.update(update)
-- emu.stopped(reset)