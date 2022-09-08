local M = {}

-- basename of file
M.basename = function(str)
    local name = string.gsub(str, "(.*/)(.*)", "%2")
    return name
end

M.file_exists = function(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

-- get directory name from filename
M.dirname = function(str)
    if str:match(".-/.-") then
        local name = string.gsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end

M.is_match = function(v, filename, filetype, filepath)
    if v.filename then
        if v.filename ~= filename then return false end
    end

    if v.filetype then
        if v.filetype ~= filetype then return false end
    end

    if v.filepath then
        if not string.find(filepath, v.filepath) then
			return false
        end
    end

    return true
end

M.menu = function(elements, show_command_in_output, window_opts)
    if next(elements) == nil then return end

    local menuelem = {}
    local commands = {}
    for _, value in ipairs(elements) do
        table.insert(menuelem, value["name"])
        table.insert(commands, value["command"])
    end

    vim.ui.select(menuelem, {
        prompt = "Select a command" -- format_item = function(item) return item end,
    }, function(label, idx)
        if label then
            local command = commands[idx]

            local bufnr = vim.api.nvim_create_buf(false, true)

            local append_data = function(_, data)
                if data then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
                end
            end

            if show_command_in_output then
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
                    "output of " .. table.concat(command) .. ":"
                })
            end

            local width = 100
            local height = 50

            local ui = vim.api.nvim_list_uis()[1]
            local opts = {
                relative = "editor",
                width = width,
                height = height,
                col = (ui.width - width) / 2,
                row = (ui.height - height) / 2,
                style = window_opts.style,
                border = window_opts.border,
                focusable = true
            }

            vim.api.nvim_open_win(bufnr, 1, opts)

            vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = append_data,
                on_stderr = append_data
            })
        end
    end)
end

return M
