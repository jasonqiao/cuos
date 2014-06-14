--[[
Handles event processing, essentially wrapping os.pullEvent
--]]

function EventLoop()
    return {
        event_handlers = {},
        is_terminated = false,
        register = function(this, event_type, func)
            this.event_handlers[event_type] = nil
        end,
        next = function(this)
            local event_info = {os.pullEvent()}
            local event_type = event_info[1]

            local callback = event_handlers[event_type]
            if callback ~= nil then
                callback(unpack(event_info))
            end
        end,
        run = function(this)
            while not this.is_terminated do
                this.next()
            end
        end,
        terminate = function(this)
            this.terminated = true
        end,
    }
end
