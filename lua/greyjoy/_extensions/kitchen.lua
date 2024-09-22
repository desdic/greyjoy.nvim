---
--- The kitchen extension is a plugin for running test kitchen (https://docs.chef.io/workstation/kitchen/)
---
---@usage default configuration for the kitchen extention
---
--- its triggered by the presence of Makefile
---
--- kitchen = {
---   group_id = nil, -- group id for toggleterm
---   targets = {"converge", "verify", "test", "destroy", "login"}, -- targets
---   include_all = false, -- include all in list
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---@tag kitchen

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

local Kitchen = {}
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

Kitchen.parse = function(fileinfo)
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

    if Kitchen.config.include_all then
        table.insert(tmp, "all")
    end

    for _, suite in ipairs(tmp) do
        if suite ~= "" then
            for _, target in ipairs(Kitchen.config.targets) do
                if valid_target(target, suite) then
                    local elem = {}
                    elem["name"] = "kitchen " .. target .. " " .. suite
                    elem["command"] = { "kitchen", target, suite }
                    elem["path"] = filepath
                    elem["plugin"] = "kitchen"
                    elem["group_id"] = Kitchen.config.group_id or nil
                    elem["pre_hook"] = Kitchen.config.pre_hook or nil
                    elem["post_hook"] = Kitchen.config.post_hook or nil
                    table.insert(elements, elem)
                end
            end
        end
    end

    return elements
end

Kitchen.health = function()
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

---@class KitchenOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field targets table?: Table with commands for test kitchen
---@field include_all boolean?: Add the `all` target in test kitchen (default: false)
---@field pre_hook function?: Function to run before running command. (default: nil)
---@field post_hook function?: Function to run after running command. (default: nil)
---
---@param config KitchenOpts?: Configuration options
Kitchen.setup = function(config)
    Kitchen.config = config

    if not Kitchen.config.targets then
        Kitchen.config["targets"] =
            { "converge", "verify", "test", "destroy", "login" }
    end

    Kitchen.config.include_all = utils.if_nil(Kitchen.config.include_all, false)
end

return greyjoy.register_extension({
    setup = Kitchen.setup,
    health = Kitchen.health,
    exports = {
        type = "file",
        files = { ".kitchen.yml" },
        parse = Kitchen.parse,
    },
})
