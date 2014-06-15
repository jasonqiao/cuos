--[[
A stub which provides the outline of a round-robin scheduler.
--]]

dofile('/lib/func.lua')

processes = {}
function scheduler()
    local event_data = nil
    local event_filters = {}
    local invoked_processes = {}
    local is_terminated = false

    while not is_terminated do
        -- Filter out any processes that don't need to be invoked, depending
        -- upon the event that was caught
        if event_data ~= nil and event_data[1] == "terminate" then
            is_terminated = true
        else
            invoked_processes = filter(
                function(_, routine)
                    return (
                        event_data == nil or
                        event_filters[routine] == event_data[1] or
                        event_filters[routine] == "")
                end,
                processes)

            -- Invoke all the routines that match
            foreach(
                function(index, routine)
                    local is_okay, param
                    if event_data ~= nil then
                        is_okay, param = coroutine.resume(routine,
                            unpack(event_data))
                    else
                        is_okay, param = coroutine.resume(routine)
                    end

                    if not is_okay then
                        error(param)
                    else
                        event_filters[routine] = param
                    end
                end,
                invoked_processes)

            -- Prune out all dead routines
            processes = filter(
                function(_, coro)
                    return coroutine.status(coro) ~= "dead"
                end,
                processes)

            event_filters = filter(
                function(coro, _)
                    return coroutine.status(coro) ~= "dead"
                end,
                event_filters)

            event_data = {os.pullEventRaw()}
        end
    end
end

function schedule(func)
    processes[#processes + 1] = coroutine.create(func)
end

function a()
    for i = 0,5,1 do
        print("A")
        sleep(1)
    end
end

function b()
    for i = 0,5,1 do
        print("B")
        sleep(1)
    end
end

function c()
    print("Waiting on C")
    sleep(10)
    print("Terminating")
    os.queueEvent('terminate')
end

schedule(a)
schedule(b)
schedule(c)
scheduler()
