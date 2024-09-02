-- Parse vscode tasks.json version 2 files
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

local health = vim.health

local M = {}
local uv = vim.uv

local valid_target = function(target, suite)
    if target ~= "login" then
        return true
    end

    if
        target == "login" and utils.file_exists(".kitchen/" .. suite .. ".yml")
    then
        return true
    end

    return false
end

M.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy kitchen" }
        )
        return {}
    end

    local filepath = fileinfo.filepath
    local elements = {}

    local original_cwd = uv.cwd()
    uv.chdir(filepath)

    local pipe = io.popen("kitchen list --bare 2>/dev/null")

    uv.chdir(original_cwd)

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

    for _, suite in ipairs(tmp) do
        if suite ~= "" then
            for _, target in ipairs(M.config.targets) do
                if valid_target(target, suite) then
                    local elem = {}
                    elem["name"] = "kitchen " .. target .. " " .. suite
                    elem["command"] = { "kitchen", target, suite }
                    elem["path"] = filepath
                    elem["plugin"] = "kitchen"
                    table.insert(elements, elem)
                end
            end
        end
    end

    return elements
end

M.health = function()
    if vim.fn.executable("kitchen") == 1 then
        health.ok("`kitchen`: Ok")
    else
        health.error(
            "`kitchen` requires kitchen (cinc-workstation/chefdk) to be installed"
        )
    end
    if vim.fn.executable("awk") == 1 then
        health.ok("`awk`: Ok")
    else
        health.error("`makefile` requires awk to be installed")
    end
end

M.setup = function(config)
    M.config = config

    if not M.config.targets then
        M.config["targets"] =
            { "converge", "verify", "test", "destroy", "login" }
    end

    M.config.include_all = utils.if_nil(M.config.include_all, false)
end

return greyjoy.register_extension({
    setup = M.setup,
    health = M.health,
    exports = { type = "file", files = { ".kitchen.yml" }, parse = M.parse },
})
