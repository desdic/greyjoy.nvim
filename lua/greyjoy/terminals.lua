local M = {}

M.term = function(command, config)
    local total_lines = vim.o.lines
    local total_cols = vim.o.columns
    local widthpct = config.ui.term.width_pct or 0.2 -- default to 20% of screen width

    local width = math.floor(total_cols * widthpct)

    local current_win = vim.api.nvim_get_current_win()
    local win_width = vim.api.nvim_win_get_width(current_win)

    if vim.g["greyjoytermid"] == nil then
        vim.api.nvim_win_set_width(current_win, win_width - width)

        local buf = vim.api.nvim_create_buf(false, true)

        local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = total_lines,
            row = 0,
            col = total_cols - width,
            style = "minimal",
            border = "none",
        })

        -- Move it to the bottom
        vim.cmd.wincmd("J")
        vim.cmd.term()
        vim.fn.jobpid(vim.o.channel)

        -- if someone defined the hight we use it
        if config.ui.term.height then
            vim.api.nvim_win_set_height(0, config.ui.term.height)
        end

        vim.g["greyjoytermid"] = win
        vim.g["greyjoychanid"] = vim.bo.channel
        vim.g["greyjoybufid"] = buf
        vim.bo[buf].buflisted = false
        vim.bo[buf].bufhidden = "hide"

        vim.api.nvim_create_autocmd({ "WinClosed", "TermClose" }, {
            callback = function(ev)
                if
                    ev.match == tostring(vim.g["greyjoytermid"])
                    or ev.buf == vim.g["greyjoybufid"]
                then
                    vim.g["greyjoytermid"] = nil
                    vim.g["greyjoychanid"] = nil
                    vim.g["greyjoybufid"] = nil
                end
            end,
        })
    end

    vim.api.nvim_set_current_win(vim.g["greyjoytermid"])
    vim.fn.bufload(vim.g["greyjoybufid"])

    local last_line = vim.api.nvim_buf_line_count(vim.g["greyjoybufid"])
    vim.api.nvim_win_set_cursor(vim.g["greyjoytermid"], { last_line, 0 })

    local commandstr = table.concat(command.command, " ") .. "\r\n"

    vim.fn.chansend(vim.g["greyjoychanid"], { commandstr })

    vim.api.nvim_set_current_win(current_win)
end

M.toggleterm = function(command, config)
    local ok, toggleterm = pcall(require, "toggleterm")
    if not ok then
        vim.notify("Unable to require toggleterm, please run healthcheck.")

        return
    end

    local count = 1 -- keep old behaviour and have all run in same terminal window
    local group_type = type(config.toggleterm.default_group_id)
    if group_type == "number" then
        count = config.toggleterm.default_group_id
    elseif group_type == "function" then
        count = config.toggleterm.default_group_id(command.plugin)
    end

    if command.group_id ~= nil then
        group_type = type(command.group_id)
        if group_type == "number" then
            count = command.group_id
        elseif group_type == "function" then
            count = command.group_id(command.plugin)
        end
    end

    -- TermExec cmd=

    local commandstr = table.concat(command.command, " ")
    local exec_command = "dir='"
        .. command.path
        .. "' cmd='"
        .. commandstr
        .. "'"
        .. " name='"
        .. commandstr
        .. "'"
    if config.ui.toggleterm.size then
        exec_command = "size="
            .. config.ui.toggleterm.size
            .. " "
            .. exec_command
    end

    toggleterm.exec_command(exec_command, count)
end

M.buffer = function(command, config)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "greyjoy", { buf = bufnr })

    local append_data = function(_, data)
        if data then
            vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        end
    end

    if config.show_command_in_output then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "output of " .. table.concat(command.command, " ") .. ":",
        })
    end

    local width = config.ui.buffer.width
    local height = config.ui.buffer.height

    local ui = vim.api.nvim_list_uis()[1]
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width - width) / 2,
        row = (ui.height - height) / 2,
        style = config.style,
        border = config.border,
        focusable = true,
    }

    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    vim.api.nvim_open_win(bufnr, true, opts)

    local commandstr = table.concat(command.command, " ")
    local shell_command = { config.default_shell, "-c", commandstr }

    vim.fn.jobstart(shell_command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
        cwd = command.path,
    })
end

return M
