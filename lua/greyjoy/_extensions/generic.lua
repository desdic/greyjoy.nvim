local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR, {title = "Plugin error"})
    return
end

local uok, utils = pcall(require, "greyjoy.utils")
if not uok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR, {title = "Plugin error"})
    return
end

local M = {}

M.parse = function(fileobj)
    if type(fileobj) ~= "table" then
        print("[generic] fileinfo must be a table")
        return {}
    end

    local filename = fileobj.filename
    local filetype = fileobj.filetype
    local filepath = fileobj.filepath

    local globalcommands = {}
    if M.config.commands then
        for k, v in pairs(M.config.commands) do
            local match = utils.is_match(v, filename, filetype, filepath)

            if match then
                local elem = {}

                elem["name"] = k
                elem["command"] = v.command
                elem["path"] = filepath

                table.insert(globalcommands, elem)
            end
        end
    end
    return globalcommands
end

return greyjoy.register_extension({
    setup = function(config) M.config = config end,
    exports = {type = "global", parse = M.parse}
})
