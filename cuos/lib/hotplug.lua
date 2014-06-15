--[[
Handles device loading, and does hotplugging.
--]]

local sides = {
    left="L", right="R",
    top="T", bottom="U", -- i.e. under
    front="F", back="B"
}

local events = cuos.import('events')

function load_devices()
    -- Clean out /dev before recreating it
    fs.delete('/dev')

    fs.makeDir('/dev')
    fs.makeDir('/dev/peripherals')
    for side, short_side in pairs(sides) do
        local handle = fs.open('/dev/peripherals/' .. side, 'w')
        local content = [==[
return nil
]==]
        local peripheral_type = peripheral.getType(side)
        if peripheral_type ~= nil then
            content = string.format([==[
return {
    side = "%s",
    type = "%s",
    methods = peripheral.wrap("%s")
]==], side, peripheral_type, side)

            -- Load the named version of the peripheral, as well
            local named_peripheral = fs.open('/dev/' .. peripheral_type
                    .. short_side, 'w')
            named_peripheral.write(content)
            named_peripheral.close()
        end

        handle.write(content)
        handle.close()
    end
end

function start()
    local handler = events.EventLoop()
    handler.register('peripheral', load_devices)
    handler.register('peripheral_detach', load_devices)

    cuos.daemon(handler.run, handler)
end
