--[[
Utilities for higher-order programming.
--]]

function foreach(func, tbl)
    for k, v in pairs(tbl) do
        func(k, v)
    end
end

function foreachl(func, list)
    for _, v in pairs(list) do
        func(v)
    end
end

function map(func, tbl)
    local new_tbl = {}
    for k, v in pairs(tbl) do
        new_tbl[k] = func(k, v)
    end
    return new_tbl
end

function mapl(func, list)
    local new_list = {}
    for _, v in pairs(list) do
        new_list[#new_list + 1] = func(v)
    end
    return new_list
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

function filterl(func, list)
    local new_list = {}
    for _, v in pairs(list) do
        if func(v) then
            new_list[#new_list + 1] = v
        end
    end
    return new_list
end

function chain(argl, ...)
    for _, func in pairs({...}) do
        func(unpack(argl))
    end
end
