---
--- Greyjoy is highly customizable and plugable runner for Neovim
---
---@usage Feature rich example using the Lazy plugin manager
---
--- > lua
--- {
---     "desdic/greyjoy.nvim",
---     keys = {
---         { "<Leader>gr", "<cmd>GreyjoyTelescope<CR>", desc = "[G]reyjoy [r]un" },
---         { "<Leader>gg", "<cmd>GreyjoyTelescope fast<CR>", desc = "[G]reyjoy fast [g]roup" },
---         { "<Leader>ge", "<cmd>Greyedit<CR>", desc = "[G]reyjoy [r]un" },
---     },
---     dependencies = {
---         { "akinsho/toggleterm.nvim" },
---     },
---     cmd = { "Greyjoy", "Greyedit", "GreyjoyTelescope" },
---     config = function()
---         local greyjoy = require("greyjoy")
---         local condition = require("greyjoy.conditions")
---
---         local tmpmakename = nil
---
---         local my_pre_hook = function(command)
---             tmpmakename = os.tmpname()
---             table.insert(command.command, "2>&1")
---             table.insert(command.command, "|")
---             table.insert(command.command, "tee")
---             table.insert(command.command, tmpmakename)
---         end
---
---         -- A bit hacky solution to checking when tee has flushed its file
---         -- but this mimics the behaviour of `:make` and its to demonstrate how
---         -- hooks can be used (requires inotifywait installed)
---         local my_post_hook = function()
---             vim.cmd(":cexpr []")
---             local cmd = { "inotifywait", "-e", "close_write", tmpmakename }
---
---             local job_id = vim.fn.jobstart(cmd, {
---                 stdout_buffered = true,
---                 on_exit = function(_, _, _)
---                     if tmpmakename ~= nil then
---                         vim.cmd(":cgetfile " .. tmpmakename)
---                         os.remove(tmpmakename)
---                     end
---                 end,
---             })
---
---             if job_id <= 0 then
---                 vim.notify("Failed to start inotifywait!")
---             end
---         end
---
---          -- Example of autocmds
---          local my_group =
---              vim.api.nvim_create_augroup("MyCustomEventGroup", { clear = true })
---
---          vim.api.nvim_create_autocmd("User", {
---              pattern = "GreyjoyBeforeExec",
---              group = my_group,
---              callback = function()
---                  print("Before run!")
---              end,
---          })
---
---          vim.api.nvim_create_autocmd("User", {
---              pattern = "GreyjoyAfterExec",
---              group = my_group,
---              callback = function()
---                  print("After run")
---              end,
---          })
---
---         greyjoy.setup({
---             output_results = require("greyjoy.terminals").toggleterm,
---             extensions = {
---                 generic = {
---                     commands = {
---                         ["run {filename}"] = { command = { "python3", "{filename}" }, filetype = "python" },
---                         ["run main.go"] = {
---                             command = { "go", "run", "main.go" },
---                             filetype = "go",
---                             filename = "main.go",
---                         },
---                         ["build main.go"] = {
---                             command = { "go", "build", "main.go" },
---                             filetype = "go",
---                             filename = "main.go",
---                         },
---                         ["zig build"] = {
---                             command = { "zig", "build" },
---                             filetype = "zig",
---                         },
---                         ["cmake --build target"] = {
---                             command = { "cd", "{rootdir}", "&&", "cmake", "--build", "{rootdir}/target" },
---                             condition = function(n)
---                                 return condition.file_exists("CMakeLists.txt", n)
---                                     and condition.directory_exists("target", n)
---                             end,
---                         },
---                         ["cmake -S . -B target"] = {
---                             command = { "cd", "{rootdir}", "&&", "cmake", "-S", ".", "-B", "{rootdir}/target" },
---                             condition = function(n)
---                                 return condition.file_exists("CMakeLists.txt", n)
---                                     and not condition.directory_exists("target", n)
---                             end,
---                         },
---                         ["build-login"] = {
---                             command = { "kitchenlogin.sh" },
---                             condition = function(n)
---                                 return condition.directory_exists("kitchen-build/.kitchen", n)
---                             end,
---                         },
---                     },
---                 },
---                 kitchen = {
---                     group_id = 2,
---                     targets = { "converge", "verify", "destroy", "test", "login" },
---                     include_all = false,
---                 },
---                 docker_compose = { group_id = 3 },
---                 cargo = { group_id = 4 },
---                 makefile = {
---                     pre_hook = my_pre_hook,
---                     post_hook = my_post_hook,
---                 },
---             },
---             run_groups = { fast = { "generic", "makefile", "cargo", "docker_compose" } },
---         })
---
---         greyjoy.load_extension("generic")
---         greyjoy.load_extension("makefile")
---         greyjoy.load_extension("kitchen")
---         greyjoy.load_extension("cargo")
---         greyjoy.load_extension("docker_compose")
---     end,
--- }
---
---@tag greyjoy.nvim

local greyjoy = {}
local config = require("greyjoy.config")
local utils = require("greyjoy.utils")
local _extensions = require("greyjoy._extensions")

---@class UIBufferOpts
---@field width number?
---@field height number?
---
---@class TogggleTermUIOpts
---@field size table?
---
---@class TelescopeOptsKeys
---@field select string?
---@field edit string?
---
---@class TelescopeOpts
---@field keys TelescopeOptsKeys
---
---@class UI
---@field buffer UIBufferOpts?
---@field toggleterm TogggleTermUIOpts?
---

---@class ToggleTermOpts
---@field default_group_id number? (default: 1)

---@class Settings
---@field ui UI?
---@field toggleterm ToggleTermOpts
---@field enable boolean? Enable/Disable running tasks (default: true)
---@field border string? Style for vim.ui.selector (default: "rounded")
---@field style string? Style for window (default: "minimal")
---@field show_command boolean? Show command to run in menu (default: false)
---@field show_command_in_output boolean? Show command in output (default: true)
---@field patterns table? List of folders that indicate the root directory of a project (default: {".git", ".svn"})
---@field output_results string?: Where to render the output. buffer or toggleterm (default: buffer)
---@field extensions table?: Configuration for all plugins (default: nil)
---@field run_groups table?: Groups of plugins to run (default: nil)
---@field overrides table?: Table used for renaming/translating commands to new commands (default: nil)
---
---@param options Settings: Configuration options
---
---@usage `require("greyjoy").setup({})`
---
greyjoy.setup = function(options)
    setmetatable(greyjoy, { __newindex = config.set, __index = config.get })

    config.defaults =
        vim.tbl_deep_extend("force", config.defaults, options or {})

    greyjoy.config = config.defaults

    _extensions.set_config(config.defaults["extensions"] or {})

    -- easy index to do lookup later
    greyjoy.run_group_map = {}
    if greyjoy.run_groups then
        for group_name, group_plugins in pairs(greyjoy.run_groups) do
            greyjoy.run_group_map[group_name] = greyjoy.run_group_map[group_name]
                or {}

            for index in ipairs(group_plugins) do
                greyjoy.run_group_map[group_name][group_plugins[index]] = true
            end
        end
    end
end

function greyjoy.__in_group(group_name, plugin_name)
    if not greyjoy.run_group_map[group_name] then
        return false
    end
    if not greyjoy.run_group_map[group_name][plugin_name] then
        return false
    end

    return true
end

---@param name string: Name of extension to load
---
---@usage `require("greyjoy").load_extension("generic")`
---
function greyjoy.load_extension(name)
    return _extensions.load(name)
end

function greyjoy.register_extension(mod)
    return _extensions.register(mod)
end

greyjoy.extensions = require("greyjoy._extensions").manager

local function generate_list(elements, overrides)
    local menuelem = {}
    local commands = {}

    for _, value in ipairs(elements) do
        local commandinput = table.concat(value.command, " ")
        local name = value.name
        local command = value.command
        local orig_command = nil
        if overrides[commandinput] then
            name = overrides[commandinput]
            -- Store original command before overwriting it
            orig_command = command
            command = utils.str_to_array(overrides[commandinput])
        end

        -- keep track of what elements we have
        table.insert(menuelem, name)
        commands[name] = {
            command = command,
            path = value.path,
            group_id = value.group_id,
            plugin = value.plugin,
            orig_command = orig_command,
        }
    end

    table.sort(menuelem)

    return menuelem, commands
end

greyjoy.execute = function(command)
    greyjoy.last_command = command

    vim.api.nvim_exec_autocmds("User", { pattern = "GreyjoyBeforeExec" })

    if command.pre_hook then
        command.pre_hook(command)
    end

    greyjoy.config.output_results(command, greyjoy.config)

    vim.api.nvim_exec_autocmds("User", { pattern = "GreyjoyAfterExec" })

    if command.post_hook then
        command.post_hook()
    end
end

greyjoy.run_last = function()
    if greyjoy.last_command then
        greyjoy.execute(greyjoy.last_command)
    end
end

greyjoy.edit = function(elements)
    if next(elements) == nil then
        return
    end

    local menuelem, commands = generate_list(elements, greyjoy.overrides)
    vim.ui.select(menuelem, { prompt = "Edit before run" }, function(label)
        if label then
            local command = commands[label]

            local commandinput = table.concat(command.command, " ")

            vim.ui.input(
                { prompt = "Edit", default = commandinput },
                function(input)
                    if input then
                        if command.orig_command then
                            local tmp = table.concat(command.orig_command, " ")
                            greyjoy.overrides[tmp] = input
                        else
                            greyjoy.overrides[commandinput] = input
                        end

                        command.command = utils.str_to_array(input)
                        greyjoy.execute(command)
                    end
                end
            )
        end
    end)
end

greyjoy.menu = function(elements)
    if next(elements) == nil then
        return
    end

    local menuelem, commands = generate_list(elements, greyjoy.overrides)
    vim.ui.select(menuelem, { prompt = "Select a command" }, function(label)
        if label then
            local command = commands[label]

            greyjoy.execute(command)
        end
    end)
end

local add_elements = function(elements, output)
    if not output then
        return
    end

    for _, elem in pairs(output) do
        if greyjoy.show_command then
            elem["name"] = elem["name"]
                .. " ("
                .. table.concat(elem["command"], " ")
                .. ")"
        end

        table.insert(elements, elem)
    end
end

greyjoy.run = function(arg, method)
    -- just return if disabled
    if not greyjoy.enable then
        return
    end

    local pluginname = arg or ""

    local fileobj = utils.new_file_obj(
        greyjoy.patterns,
        vim.api.nvim_buf_get_name(0),
        vim.bo.filetype
    )
    local rootdir = fileobj.rootdir
    local elements = {}

    for p, v in pairs(greyjoy.extensions) do
        if
            pluginname == ""
            or pluginname == p
            or greyjoy.__in_group(pluginname, p)
        then
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
                                filepath = rootdir,
                            }
                            local output = v.parse(fileinfo)
                            add_elements(elements, output)
                        end
                    end
                end
            end
        end
    end

    if method == "edit" then
        greyjoy.edit(elements)
    else
        greyjoy.menu(elements)
    end
end

vim.api.nvim_create_user_command("Greyjoy", function(args)
    greyjoy.run(args.args)
end, { nargs = "*", desc = "Run greyjoy" })

vim.api.nvim_create_user_command("Greyedit", function(args)
    greyjoy.run(args.args, "edit")
end, { nargs = "*", desc = "Edit greyjoy" })

vim.api.nvim_create_user_command("GreyjoyRunLast", function()
    greyjoy.run_last()
end, { nargs = "*", desc = "Run last greyjoy command" })

local has_telescope, _ = pcall(require, "telescope")
if has_telescope then
    vim.api.nvim_create_user_command("GreyjoyTelescope", function(args)
        require("greyjoy.telescope").run(args.args)
    end, { nargs = "*", desc = "Run greyjoy via telescope" })
end

local has_fzf, _ = pcall(require, "fzf-lua")
if has_fzf then
    vim.api.nvim_create_user_command("GreyjoyFzf", function(args)
        require("greyjoy.fzf").run(args.args)
    end, { nargs = "*", desc = "Run greyjoy via fzf" })
end

return greyjoy
