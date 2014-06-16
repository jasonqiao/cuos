--[[
A small networking library intended to mimick the Berkeley sockets API.
--]]

cuos.import('events')

function datagram_packet(host, port, data)
    return {
        type = 'datagram',
        source = os.getComputerID(),
        dest = host,
        port = port,
        data = data,
    }
end

function Datagram(device)
    local modem = cuos.dev(device)
    if modem == nil then
        return nil
    else
        return {
            modem = modem,
            bound_ports = {},
            bind = function(this, port)
                this.modem.methods.open(port)
                this.bound_ports[port] = true
            end,
            close = function(this)
                for port, _ in pairs(this.bound_ports) do
                    this.modem.close(port)
                    this.bound_ports[port] = nil
                end
            end,
            sendto = function(this, host, port, message)
                this.modem.methods.transmit(port, port,
                    datagram_packet(host, port, message))
            end,
            recvfrom = function(this, host, port)
                local event_handler = events.EventLoop()
                local recv_host, recv_port, recv_data

                if port ~= nil and this.bound_ports[port] ~= true then
                    error('Cannot listen on unbound port')
                end

                event_handler:register('modem_message',
                    function(event, side, send_chan, reply_chan, packet, dist)
                        local is_our_modem = (
                            side == modem.side
                        )

                        -- Since we receive all packets with wireless modems,
                        -- we have to drop some that aren't ours
                        local is_packet_to_us = (
                            packet.dest == os.getComputerID() or
                            packet.dest == nil -- A broadcast packet
                            )

                        local host_matches = (
                            host == nil or
                            packet.source == host)

                        local port_matches = (
                            port == nil or
                            packet.port == port)

                        if (packet.type == "datagram" and
                                is_packet_to_us and
                                host_matches and 
                                port_matches) then
                            recv_host = packet.source
                            recv_port = packet.port
                            recv_data = packet.data
                            event_handler:terminate()
                        end
                    end)
                event_handler:run()

                return recv_host, recv_port, recv_data
            end,
        }
    end
end
