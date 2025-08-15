---
--- The file extension
---
---@usage default configuration for the file extension
---
--- > lua
--- file = {
---   filename = "greyjoy.json"
--- }
---

--- Parses a local file called greyjoy.json with key/value structure like
---
--- {
---   "do build": ["make build"],
---   "do stuff": ["touch config.json"]
--- }

---@tag greyjoy.file

local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.log.levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local File = {}

local read_json = function(filepath)
    local data = {}

    if vim.fn.filereadable(filepath) ~= 0 then
        local fd = io.open(filepath, "r")
        if fd then
            local content = fd:read("*a")
            io.close(fd)
            data = vim.fn.json_decode(content)
        end
    end
    return data
end

local compile_commands = function(data, filepath, fileobj)
    local file_commands = {}

    local substitute_variables = require("greyjoy.utils").substitute_variables
    for key, value in pairs(data) do
        local command = substitute_variables(value, fileobj)

        table.insert(file_commands, {
            name = key,
            command = command,
            path = filepath,
            plugin = "file",
            pre_hook = File.config.pre_hook or nil,
            post_hook = File.config.post_hook or nil,
        })
    end
    return file_commands
end

File.parse = function(fileobj)
    if type(fileobj) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy generic" }
        )
        return {}
    end

    local filename = File.config.filename or "greyjoy.json"

    local data_file = vim.fs.find({ filename }, { upward = true })[1]
    if not data_file then
        return {}
    end

    local data = read_json(data_file)
    local filepath = vim.fs.dirname(data_file)

    return compile_commands(data, filepath, fileobj)
end

File.setup = function(config)
    File.config = config
end

return greyjoy.register_extension({
    setup = File.setup,
    health = File.health,
    exports = {
        type = "global",
        parse = File.parse,
    },
})
