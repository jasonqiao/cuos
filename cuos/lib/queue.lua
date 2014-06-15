--[[
A simple queue implementation.
--]]

function Queue()
    return {
        items = {},
        left = 0,
        right = 1,
        is_empty = function(this)
            return math.abs(this.left - this.right) == 1
        end,
        push_left = function(this, value)
            this.left = this.left - 1
            this.items[this.left] = value
        end,
        push_right = function(this, value)
            this.right = this.right + 1
            this.items[this.right] = value
        end,
        pop_left = function(this)
            if this:is_empty() then
                return nil
            else
                local value = this.items[this.left]
                this.items[this.left] = nil
                this.left = this.left + 1
                return value
            end
        end,
        pop_right = function(this)
            if this:is_empty() then
                return nil
            else
                local value = this.items[this.right]
                this.items[this.right] = nil
                this.right = this.right - 1
                return value
            end
        end
    }
end
