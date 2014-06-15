--[[
A stub which loads all the entries in the /dev filesystem.
--]]

SIDES = {left='L', right='R', top='T', bottom='U', front='F', back='B'}

-- Clean out the directory structure of /dev
fs.delete('/dev')

fs.makeDir('/dev')
fs.makeDir('/dev/peripherals')
for side, short_side in pairs(SIDES) do
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
}
]==], side, peripheral_type, side)

        -- Added the named version of the peripheral
        local named_peripheral = fs.open('/dev/' .. peripheral_type 
                .. short_side, 'w')
        named_peripheral.write(content)
        named_peripheral.close()
    end

    handle.write(content)
    handle.close()
end
