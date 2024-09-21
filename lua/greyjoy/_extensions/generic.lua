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

local M = {}

M.parse = function(fileobj)
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
    if M.config.commands then
        for k, v in pairs(M.config.commands) do
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
                elem["pre_hook"] = v.pre_hook or nil
                elem["post_hook"] = v.post_hook or nil

                table.insert(globalcommands, elem)
            end
        end
    end
    return globalcommands
end

return greyjoy.register_extension({
    setup = function(config)
        M.config = config
    end,
    exports = { type = "global", parse = M.parse },
})
