local greyjoy = {}
local config = require("greyjoy.config")
local utils = require("greyjoy.utils")
local _extensions = require("greyjoy._extensions")

-- Override defaults with configuration
greyjoy.setup = function(options)
    setmetatable(greyjoy, {__newindex = config.set, __index = config.get})

    if options ~= nil then
        for k, v in pairs(options) do config.defaults[k] = v end
    end

    _extensions.set_config(config.defaults["extensions"] or {})

    greyjoy.last_element = {}

    -- easy index to do lookup later
    greyjoy.run_group_map = {}
    if greyjoy.run_groups then
        for group_name, group_plugins in pairs(greyjoy.run_groups) do
            greyjoy.run_group_map[group_name] =
                greyjoy.run_group_map[group_name] or {}

            for index in ipairs(group_plugins) do
                greyjoy.run_group_map[group_name][group_plugins[index]] = true
            end
        end
    end
end

function greyjoy.__in_group(group_name, plugin_name)
    if not greyjoy.run_group_map[group_name] then return false end
    if not greyjoy.run_group_map[group_name][plugin_name] then return false end

    return true
end

function greyjoy.load_extension(name) return _extensions.load(name) end

function greyjoy.register_extension(mod) return _extensions.register(mod) end

greyjoy.extensions = require("greyjoy._extensions").manager

greyjoy.menu = function(rootdir, elements)
    if next(elements) == nil then return end

    local menuelem = {}
    local menulookup = {}
    local commands = {}
    for _, value in ipairs(elements) do
        -- keep track of what elements we have
        menulookup[value["name"]] = true
        table.insert(menuelem, value["name"])
        commands[value["name"]] = {
            command = value["command"],
            path = value["path"]
        }
    end

    table.sort(menuelem)
    if utils.if_nil(greyjoy.last_first, false) then
        if utils.if_nil(greyjoy.last_element[rootdir], "") ~= "" then
            for index, value in ipairs(menuelem) do
                if value == greyjoy.last_element[rootdir] then
                    table.remove(menuelem, index)
                end
            end
            -- only add it if its supposed to be on the list
            if menulookup[greyjoy.last_element[rootdir]] then
                table.insert(menuelem, 1, greyjoy.last_element[rootdir])
            end
        end
    end

    vim.ui.select(menuelem, {prompt = "Select a command"}, function(label, _)
        if label then
            greyjoy.last_element[rootdir] = label
            local command = commands[label]

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
        vim.notify("Unable to require toggleterm, please run healthcheck.")

        return
    end

    local commandstr = table.concat(command.command, " ")
    local exec_command = "dir='" .. command.path .. "' cmd='" .. commandstr .. "'"
    if greyjoy.ui.toggleterm.size then
      exec_command = "size=" .. greyjoy.ui.toggleterm.size .. " " .. exec_command
    end
    toggleterm.exec_command(exec_command)
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
            "output of " .. table.concat(command.command) .. ":"
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

    vim.fn.jobstart(command.command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
        cwd = command.path
    })
end

local add_elements = function(elements, output)
    if not output then return end

    for _, elem in pairs(output) do
        if greyjoy.show_command then
            elem["name"] = elem["name"] .. " (" ..
                               table.concat(elem["command"], " ") .. ")"
        end

        table.insert(elements, elem)
    end
end

greyjoy.run = function(arg)
    -- just return if disabled
    if not greyjoy.enable then return end

    local filetype = vim.bo.filetype
    local fullname = vim.api.nvim_buf_get_name(0)
    local filename = vim.fs.basename(fullname)
    local filepath = vim.fs.dirname(fullname)
    local pluginname = arg or ""

    filepath = utils.if_nil(filepath, "")
    if filepath == "" then filepath = vim.loop.cwd() end

    local rootdir = vim.fs.dirname(vim.fs.find(greyjoy.patterns, { upward = true })[1])
    rootdir = utils.if_nil(rootdir, filepath)

    local fileobj = {
        filetype = filetype,
        fullname = fullname,
        filename = filename,
        filepath = filepath
    }

    local elements = {}

    for p, v in pairs(greyjoy.extensions) do
        if pluginname == "" or pluginname == p or
            greyjoy.__in_group(pluginname, p) then
            -- greyjoy.run_group_map[pluginname][p] then
            -- Do global based
            if v.type == "global" then
                local output = v.parse(fileobj)
                add_elements(elements, output)

                -- Do file based extensions
            elseif v.type == "file" then
                if rootdir then
                    for _, file in pairs(v.files) do
                        if utils.file_exists(rootdir .. "/" .. file) then
                            local fileinfo = {
                                filename = file,
                                filepath = rootdir
                            }
                            local output = v.parse(fileinfo)
                            add_elements(elements, output)
                        end
                    end
                end
            end
        end
    end

    greyjoy.menu(rootdir, elements)
end

vim.api.nvim_create_user_command("Greyjoy",
                                 function(args) greyjoy.run(args.args) end,
                                 {nargs = "*", desc = "Run greyjoy"})

return greyjoy
