---
--- The generic extension
---
---@usage default configuration for the generic extension
---
--- > lua
--- generic = {
---   commands = {},
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---
---@tag greyjoy.generic

local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.log.levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local uok, utils = pcall(require, "greyjoy.utils")
if not uok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.log.levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local Generic = {}

Generic.parse = function(fileobj)
    if type(fileobj) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy generic" }
        )
        return {}
    end

    local filename = fileobj.filename
    local filetype = fileobj.filetype
    local filepath = fileobj.filepath
    local rootdir = fileobj.rootdir

    local globalcommands = {}
    if Generic.config.commands then
        for k, v in pairs(Generic.config.commands) do
            local match =
                utils.is_match(v, filename, filetype, filepath, rootdir)

            if match then
                local elem = {}

                -- replace variables in name
                k = k:gsub("{filename}", filename)
                k = k:gsub("{filepath}", filepath)
                k = k:gsub("{rootdir}", rootdir)

                -- clone command and replace variables
                local command = {}
                for index in ipairs(v.command) do
                    local celem = v.command[index]
                    celem = celem:gsub("{filename}", filename)
                    celem = celem:gsub("{filepath}", filepath)
                    celem = celem:gsub("{rootdir}", rootdir)

                    table.insert(command, celem)
                end

                elem["name"] = k
                elem["command"] = command
                elem["path"] = filepath
                elem["plugin"] = "generic"
                elem["group_id"] = Generic.config.group_id or nil
                elem["pre_hook"] = v.pre_hook or nil
                elem["post_hook"] = v.post_hook or nil

                table.insert(globalcommands, elem)
            end
        end
    end
    return globalcommands
end

---@class CommandOpts
---@field command table: Command with parameters to run (example: command = { "go", "run", "main.go" })
---@field filetype string?: Trigger on a specific filetype. (example: filetype = "go")
---@field filename string?: Trigger on a specific filename. (example: filetype = "main.go")
---@field condition function?: Trigger via a function.
---
--- The command table supports a few variables/substituions where name is replaced.
---
--- {filename} is replaced with current filename
--- {filepath} is replaced with current filepath
--- {rootdir} is the path for the root directory
---
--- Having multiple conditions like filetype and filename will do an `and` operation so both requirements has to be met before it triggers.
--- Examples:
---     commands = {
---         ["run {filename}"] = {
---             command = { "python3", "{filename}" },
---             filetype = "python",
---         },
---         ["run main.go"] = {
---             command = { "go", "run", "main.go" },
---             filetype = "go",
---             filename = "main.go",
---         },
---         ["cmake --build target"] = {
---             command = { "cd", "{rootdir}", "&&", "cmake", "--build", "{rootdir}/target" },
---             condition = function(fileobj)
---                 return require("greyjoy.conditions").file_exists("CMakeLists.txt", fileobj)
---                     and require("greyjoy.conditions").directory_exists("target", fileobj)
---             end,
---         },

---@class GenericOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field commands CommandOpts?: Configuration of commands and when to run. (default: nil)
---@field pre_hook function?: Function to run before running command. (default: nil)
---@field post_hook function?: Function to run after running command. (default: nil)
---
---@param config GenericOpts?: Configuration options
Generic.setup = function(config)
    Generic.config = config
end

return greyjoy.register_extension({
    setup = Generic.setup,
    exports = { type = "global", parse = Generic.parse },
})
