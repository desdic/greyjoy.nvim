local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.log.levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local health = vim.health

local M = {}

M.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy cargo" }
        )
        return {}
    end

    local filepath = fileinfo.filepath
    local elements = {}

    if M.config.targets then
        for _, v in ipairs(M.config.targets) do
            local elem = {}
            local name = "cargo"
            local cmd = { "cargo" }

            for _, option in ipairs(v) do
                name = name .. " " .. option
                table.insert(cmd, option)
            end

            elem["name"] = name
            elem["command"] = cmd
            elem["path"] = filepath
            elem["plugin"] = "cargo"

            table.insert(elements, elem)
        end
    end

    return elements
end

M.health = function()
    if vim.fn.executable("cargo") == 1 then
        health.ok("`cargo`: Ok")
    else
        health.error("`cargo` requires cargo to be installed")
    end
end

return greyjoy.register_extension({
    setup = function(config)
        M.config = config

        if not M.config.targets then
            M.config = {
                targets = {
                    { "build" },
                    { "build", "--release" },
                    { "check" },
                    { "clean" },
                    { "update" },
                    { "run" },
                },
            }
        end
    end,
    health = M.health,
    exports = { type = "file", files = { "Cargo.toml" }, parse = M.parse },
})
