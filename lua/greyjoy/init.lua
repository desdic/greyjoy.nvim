local greyjoy = {}
local config = require("greyjoy.config")
local utils = require("greyjoy.utils")
local findroot = require("greyjoy.findroot")
local _extensions = require("greyjoy._extensions")

-- Override defaults with configuration
greyjoy.setup = function(options)
    setmetatable(greyjoy, {__newindex = config.set, __index = config.get})

    if options ~= nil then
        for k, v in pairs(options) do config.defaults[k] = v end
    end

    _extensions.set_config(config.defaults["extensions"] or {})
end

function greyjoy.load_extension(name) return _extensions.load(name) end

function greyjoy.register_extension(mod) return _extensions.register(mod) end

greyjoy.extensions = require("greyjoy._extensions").manager

greyjoy.menu = function(elements)
    if next(elements) == nil then return end

    local menuelem = {}
    local commands = {}
    for _, value in ipairs(elements) do
        table.insert(menuelem, value["name"])
        table.insert(commands, value["command"])
    end

    vim.ui.select(menuelem, {
        prompt = "Select a command"
    }, function(label, idx)
        if label then
            local command = commands[idx]
            if greyjoy.output_results == "toggleterm" then
                greyjoy.to_toggleterm(command)
            else
                greyjoy.to_buffer(command)
            end
        end
    end)
end

greyjoy.to_toggleterm = function(command)
    local ok, toggleterm = pcall(require, "toggleterm")
    if not ok then
        vim.notify("Unable to require toggleterm, defaulting to buffer")

        greyjoy.to_buffer(command)
        return
    end

    local commandstr = table.concat(command, " ")
    toggleterm.exec_command("cmd='" .. string.format("%q", commandstr) .. "'")
end

greyjoy.to_buffer = function(command)
    local bufnr = vim.api.nvim_create_buf(false, true)

    local append_data = function(_, data)
        if data then
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        end
    end

    if greyjoy.show_command_in_output then
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
        style = greyjoy.style,
        border = greyjoy.border,
        focusable = true
    }

    vim.api.nvim_open_win(bufnr, 1, opts)

    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data
    })
end

greyjoy.run = function(_)
    -- just return if disabled
    if not greyjoy.enable then return end

    local filetype = vim.bo.filetype
    local fullname = vim.api.nvim_buf_get_name(0)
    local filename = utils.basename(fullname)
    local filepath = utils.dirname(fullname)

    local fileobj = {
        filetype = filetype,
        fullname = fullname,
        filename = filename,
        filepath = filepath
    }

    local elements = {}

    local rootdir = findroot.find(greyjoy.patterns, filepath)

    for _, v in pairs(greyjoy.extensions) do
        -- Do global based
        if v.type == "global" then
            local output = v.parse(fileobj)
            if output then
                for _, elem in pairs(output) do
                    if greyjoy.show_command then
                        elem["name"] = elem["name"] .. " (" ..
                                           table.concat(elem["command"], " ") ..
                                           ")"
                    end

                    table.insert(elements, elem)
                end
            end
        end

        -- Do file based extensions
        if v.type == "file" then
            if rootdir then
                for _, file in pairs(v.files) do
                    if utils.file_exists(rootdir .. "/" .. file) then
                        local fileinfo = {filename = file, filepath = rootdir}
                        local output = v.parse(fileinfo)
                        if output then
                            for _, elem in pairs(output) do
                                if greyjoy.show_command then
                                    elem["name"] =
                                        elem["name"] .. " (" ..
                                            table.concat(elem["command"], " ") ..
                                            ")"
                                end

                                table.insert(elements, elem)
                            end
                        end
                    end
                end
            end
        end
    end

    greyjoy.menu(elements)
end

vim.api.nvim_create_user_command("Greyjoy", function(args) greyjoy.run(args) end,
                                 {nargs = "*", desc = "Run greyjoy"})

return greyjoy
