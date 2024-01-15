-- Parse vscode tasks.json version 2 files
local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local uok, utils = pcall(require, "greyjoy.utils")
if not uok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local health = vim.health or require("health")

local M = {}

M.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        print("[kitchen] fileinfo must be a table")
        return {}
    end

    local filepath = fileinfo.filepath
    local elements = {}

    local original_cwd = vim.loop.cwd()
    vim.loop.chdir(filepath)

    local pipe = io.popen("kitchen list --bare 2>/dev/null")

    vim.loop.chdir(original_cwd)

    if not pipe then
        return elements
    end

    local data = pipe:read("*a")
    io.close(pipe)

    if #data == 0 then
        return elements
    end

    local tmp = vim.split(string.sub(data, 1, #data - 1), "\n")

    if M.config.include_all then
        table.insert(tmp, "all")
    end

    for _, v in ipairs(tmp) do
        if v ~= "" then
            for _, target in ipairs(M.config.targets) do
                local elem = {}
                elem["name"] = "kitchen " .. target .. " " .. v
                elem["command"] = { "kitchen", target, v }
                elem["path"] = filepath
                elem["plugin"] = "kitchen"
                table.insert(elements, elem)
            end
        end
    end

    return elements
end

M.health = function()
    if vim.fn.executable("kitchen") == 1 then
        health.report_ok("`kitchen`: Ok")
    else
        health.report_error(
            "`kitchen` requires kitchen (cinc-workstation/chefdk) to be installed"
        )
    end
    if vim.fn.executable("awk") == 1 then
        health.report_ok("`awk`: Ok")
    else
        health.report_error("`makefile` requires awk to be installed")
    end
end

M.setup = function(config)
    M.config = config

    if not M.config.targets then
        M.config["targets"] = { "converge", "verify", "test", "destroy" }
    end

    M.config.include_all = utils.if_nil(M.config.include_all, false)
end

return greyjoy.register_extension({
    setup = M.setup,
    health = M.health,
    exports = { type = "file", files = { ".kitchen.yml" }, parse = M.parse },
})
