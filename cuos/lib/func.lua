--[[
Utilities for higher-order programming.
--]]

function foreach(func, tbl)
    for k, v in pairs(tbl) do
        func(k, v)
    end
end

function map(func, tbl)
    local new_tbl = {}
    for k, v in pairs(tbl) do
        new_tbl[k] = func(k, v)
    end
    return new_tbl
end

function filter(func, tbl)
    local new_tbl = {}
    for k, v in pairs(tbl) do
        if func(k, v) then
            new_tbl[k] = v
        else
            new_tbl[k] = nil
        end
    end
    return new_tbl
end

function chain(argl, ...)
    for _, func in pairs({...}) do
        func(unpack(argl))
    end
end
