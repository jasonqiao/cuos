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
        local new_k, new_v = func(k, v)
        if new_v == nil then
            -- Assume that the function returned only a value
            -- if it returned a single value (since nil is an
            -- invalid table key)
            new_v = new_k
            new_k = k
        end
        new_tbl[new_k] = new_v
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
