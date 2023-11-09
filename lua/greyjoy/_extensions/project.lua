local utils = require("greyjoy.utils")
local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local M = {}

M.readfile = function(filename)
    if not utils.file_exists(filename) then
        return nil
    end
    local content = vim.fn.readfile(filename)
    local obj = vim.fn.json_decode(content)
    return obj
end

M.parse = function(fileobj)
    local globalcommands = {}
    -- Reuse the greyjoy patterns to find root of project
    local rootdir =
        vim.fs.dirname(vim.fs.find(greyjoy.patterns, { upward = true })[1])
    local filename = rootdir .. "/greyjoy.json"

    local obj = M.readfile(filename)
    if obj then
        for key, value in pairs(obj) do
            print(vim.inspect(key, value))
        end
    end

    return globalcommands
end

return greyjoy.register_extension({
    setup = function(config)
        M.config = config
    end,
    exports = {
        type = "global",
        parse = M.parse,
    },
})
