--[[
A more complete way to do terminal line editing.
--]]

cuos.import('deque')
cuos.import('events')

function readline(prompt, history)
    local events = events.EventLoop()

    -- Go ahead and put out the initial prompt, so that we know where the
    -- cursor should be
    term.write(prompt)
    
    -- Get the location of the cursor, while respecting the prompt
    local cursor_orig_x, cursor_orig_y = term.getCursorPos()
    local term_width, term_height = term.getSize()
    local prompt_length = string.len(prompt)

    local before_cursor = deque.Deque()
    local after_cursor = deque.Deque()

    if history == nil then
        history = deque.Deque()
    end
    local pre_history = deque.fromiter(history:iterleft()) 
    local post_history = deque.Deque()

    function buffer_as_string(cursor)
        local text = {}
        for char in before_cursor:iterleft() do
            text[#text + 1] = char
        end

        if cursor then
            text[#text + 1] = '_'
        end

        for char in after_cursor:iterleft() do
            text[#text + 1] = char
        end

        return table.concat(text, "")
    end

    function place_cursor()
        local pre_cursor_length = before_cursor:len()
        local line = cursor_orig_y
        local line_width = term_width - prompt_length

        while pre_cursor_length >= line do
            line = line + 1
            pre_cursor_length = pre_cursor_length - line_width
        end

        term.setCursorPos(pre_cursor_length + prompt_length, line)
    end

    function print_buffer()
        -- Clear all of the lines previously used to draw our text
        local term_current_x, term_current_y = term.getCursorPos()
        for line = term_current_y, cursor_orig_y, -1 do
            term.setCursorPos(1, line)
            term.clearLine()
        end

        term.setCursorPos(1, cursor_orig_y)
       
        local buffer_text = buffer_as_string(true)
        local line_length = term_width - prompt_length
        local term_row = cursor_orig_y
        local line = ""

        while buffer_text ~= "" do
            line = string.sub(buffer_text, 1, line_length)
            buffer_text = string.sub(buffer_text, line_length + 1)

            term.write(prompt .. line)
            term_row = term_row + 1
            if term_row > term_height then
                -- If we've hit the bottom of the screen, then scroll the
                -- terminal down a line and keep working
                term.scroll(1)
                cursor_orig_y = cursor_orig_y - 1

                if cursor_orig_y == 0 then
                    error('Current line too long for screen - aborting')
                end
                term_row = term_row - 1
                return
            end
            term.setCursorPos(1, term_row)
        end

        place_cursor()
    end

    function insert_at_cursor(char)
        before_cursor:pushright(char)
        print_buffer()
    end

    function delete_before_cursor()
        if not before_cursor:empty() then
            before_cursor:popright()
            print_buffer()
        end
    end

    function delete_after_cursor()
        if not after_cursor:empty() then
            after_cursor:popleft()
            print_buffer()
        end
    end

    function cursor_left()
        if not before_cursor:empty() then
            local char = before_cursor:popright()
            after_cursor:pushleft(char)
            print_buffer()
        end
    end

    function cursor_right()
        if not after_cursor:empty() then
            local char = after_cursor:popleft()
            before_cursor:pushright(char)
            print_buffer()
        end
    end
    
    function cursor_home()
        while not before_cursor:empty() do
            cursor_left()
        end
        print_buffer()
    end

    function cursor_end()
        while not after_cursor:empty() do
            cursor_right()
        end
        print_buffer()
    end

    function replace_current_line(text)
        before_cursor:clear()
        after_cursor:clear()

        for idx = 1,string.len(text),1 do
            before_cursor:pushright(string.sub(text,idx,idx))
        end

        -- If nothing is in the buffer, then the current line may not
        -- be cleared; clear it just in case.
        term.clearLine()

        print_buffer()
    end

    function move_prev_history()
        if not pre_history:empty() then
            local current_entry = buffer_as_string()
            local old_entry = pre_history:popright()
            post_history:pushleft(current_entry)
            replace_current_line(old_entry)
        end
    end

    function move_next_history()
        if not post_history:empty() then
            local current_entry = buffer_as_string()
            local new_entry = post_history:popleft()
            pre_history:pushright(current_entry)
            replace_current_line(new_entry)
        end
    end

    events:register('key',
            function(event, key)
                if key == 205 then
                    cursor_right()
                elseif key == 203 then
                    cursor_left()
                elseif key == 208 then
                    move_next_history()
                elseif key == 200 then
                    move_prev_history()
                elseif key == 199 then
                    cursor_home()
                elseif key == 207 then
                    cursor_end()
                elseif key == 14 then
                    delete_before_cursor()
                elseif key == 211 then
                    delete_after_cursor()
                elseif key == 28 then
                    events:terminate()
                end
            end)

    events:register('char',
            function(event, character)
                insert_at_cursor(character)
            end)

    events:run()
    place_cursor()

    local final_x, final_y = term.getCursorPos()
    if final_y == term_height then
        term.scroll(1)
        final_y = final_y - 1
    end 
    term.setCursorPos(1, final_y)
    term.clearLine()

    local entry = buffer_as_string()
    history:pushright(entry)
    return entry
end
