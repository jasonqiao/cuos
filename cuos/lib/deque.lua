--[[
A double-ended queue implementation.
--]]

function Deque()
    return {
        data = {},
        left = 0,
        right = 0,

        tolist = function(this)
            local list = {}
            local list_index = 1
            for real_index = this.left + 1, this.right, 1 do
                list[list_index] = this.data[real_index]
                list_index = list_index + 1
            end
            return list
        end,
        len = function(this)
            return this.right - this.left
        end,
        iterleft = function(this)
            local index = this.left
            return function()
                if index == this.right then
                    return nil
                else
                    index = index - 1
                    return this.data[index]
                end
            end
        end,
        iterright = function(this)
            local index = this.right
            return function()
                if index == this.left then
                    return nil
                else
                    local value = this.data[index]
                    index = index - 1
                    return value
                end
            end
        end,
        empty = function(this)
            return this.left == this.right
        end,
        clear = function(this)
            this.data = {}
            this.left = 0
            this.right = 0
        end,
        pushleft = function(this, value)
            this.data[this.left] = value
            this.left = this.left - 1
        end,
        pushright = function(this, value)
            this.right = this.right + 1
            this.data[this.right] = value
        end,
        popleft = function(this, value)
            if this:is_empty() then
                error('Empty deque')
            end

            this.left = this.left + 1
            local value = this.data[this.left]
            this.data[this.left] = nil
            return value
        end,
        popright = function(this, value)
            if this:is_empty() then
                error('Empty deque')
            end

            local value = this.data[this.right]
            this.data[this.right] = nil
            this.right = this.right - 1
            return value
        end
    }
end
