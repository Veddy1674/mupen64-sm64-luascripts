-- A debug lua file

function wait(seconds)
    local start_time = os.clock()
    while os.clock() - start_time < seconds do
        -- empty
    end
end

local wait_time = 0 -- only one wait per time?
local waiting = false
function start_wait(seconds)
    wait_time = os.clock() + seconds
    waiting = true
end

function start()
	-- Works:
	
	-- print("hello")
	-- wait(3)
	-- print("its been 3 sec")
	
	-- doesn't work, maybe make two functions..? or make a listener in update() that waits for the next wait function
	start_wait(1)
	print("yaaey")
	start_wait(2)
	print("i like waiting")
end

function update()
	-- makes the game extremely laggy:
	
	-- print("test")
	-- wait(1)
	
	-- works perfect
	-- if waiting then
        -- if os.clock() >= wait_time then
            -- waiting = false
            -- print("waited")
        -- else
            -- return
        -- end
    -- else
        -- print("more code?")
        -- start_wait(1)
    -- end
end

start()

emu.atinput(update)