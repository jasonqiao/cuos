--[[
A distributed, peer-to-peer service for naming hosts.
--]]

cuos.import('func') -- TODO: DELETE ME!
cuos.import('events')
cuos.import('socket')

local naming_port = 1001
local announce_interval = 10
local drop_interval = 15
local announce_event = 'announce'
local conflict_event = 'conflict'

local hostname = nil
local bindings = {}

function service()
    handler = events.EventLoop()

    local modem = cuos.get_peripheral('modem')
    -- How long since each binding has been last refreshed
    local binding_age = {}
    local datagram = nil
    local timer = nil

    function reload_socket()
        if datagram ~= nil then
            datagram:close()
        end

        modem = cuos.get_peripheral('modem')
        if modem ~= nil then
            datagram = socket.Datagram(modem)
            datagram:bind(naming_port)
        else
            datagram = nil
        end
    end

    handler:register('peripheral',
            function(event, side)
                if modem == nil then
                    reload_socket()
                end
            end)

    handler:register('peripheral_detach',
            function(event, side)
                -- Only try to realod if we're losing our modem
                if modem ~= nil and side == modem.side then
                    reload_socket()
                end
            end)
    
    handler:register('timer',
        function(event, timer_id)
            if timer_id == timer then
                -- Refresh our hostname on the network
                if datagram ~= nil then
                    
                datagram:sendto(nil, naming_port,
                        {event = announce_event, name = hostname})
                end

                -- Drop any stale bindings which haven't been updated
                -- recently
                local now = os.clock()
                local host, age
                for name, last_update in pairs(binding_age) do
                    if now - last_update > drop_interval then
                        binding_age[name] = nil
                        bindings[name] = nil
                    end
                end

                timer = os.startTimer(announce_interval)
            end
        end)

    handler:register('datagram_recv',
        function(event, token)
            local datagram
            local host
            local port
            local message

            datagram, host, port, message = socket.get_last_message(token)
            local peer_name = message.name
            if message.event == announce_event then
                -- Make sure there are no naming clashes - if there are, then
                -- send a conflict message
                local old_host = bindings[peer_name]
                if old_host == nil or old_host == host then
                    bindings[peer_name] = host
                    binding_age[peer_name] = os.clock()
                else
                    datagram:sendto(host, port, {event = conflit_event})
                end
            elseif message.event == conflict_event then
                print("Hostname conflict - name service cannot continue!")
                datagram:close()
                handler:terminate()
            end
        end)

    -- Run the update function immediately, to get our hostname out there
    timer = os.startTimer(0)

    reload_socket()
    while not handler.is_terminated do
        if datagram ~= nil then
            datagram:hook_recvfrom(handler, nil, naming_port)
            handler:next()
        else
            handler:register('modem_event', nil)
            handler:next()
        end
    end
end

function start()
    local hostfile = fs.open('/etc/hostname', 'r')
    if hostfile == nil then
        print('No hostname - not registering on network')
    else
        hostname = hostfile.readLine()

        if tonumber(hostname) ~= nil then
            print('You cannot have a purely numeric hostname')
            hostname = nil
        end
        hostfile.close()
    end

    if hostname ~= nil then
        bindings[hostname] = os.getComputerID()
        cuos.daemon(service)
    end
end

function resolve(name)
    if tonumber(name) ~= nil then
        return tonumber(name)
    else
        return bindings[name]
    end
end
