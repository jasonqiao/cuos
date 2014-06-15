--[[
A stub which provides the outline of a round-robin scheduler.
--]]

load('/lib/queue.lua')

processes = Queue()
is_terminated = false
function scheduler()
    while not is_terminated do
        local current = current:pop_left()
        if current ~= nil then
            sleep(1)
        else
            coroutine.resume(current)
            if coroutine.status() ~= "dead" then
                current:push_right(current)
            end
        end
    end
end

function schedule(func)
    processes.push_right(coroutine.create(func))
end

function a()
    for i = 0,5,1 do
        print("A")
        coroutine.yield()
    end
end

function b()
    for i = 0,5,1 do
        print("B")
        coroutine.yield()
    end
end

function c()
    sleep(10)
    is_terminated = true
end

schedule(a)
schedule(b)
scheduler()
