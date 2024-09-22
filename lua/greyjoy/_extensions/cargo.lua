---
--- The cargo extension builds common usage for the cargo command
---
---@usage default configuration for the cargo extention
---
--- its triggered by the presence of Cargo.toml
---
--- > lua
--- cargo = {
---   group_id = nil, -- group id for toggleterm
---   targets = {
---       { "build" },
---       { "build", "--release" },
---       { "check" },
---       { "clean" },
---       { "update" },
---       { "run" },
---   },
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---
---@tag greyjoy.cargo

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

local Cargo = {}

Cargo.parse = function(fileinfo)
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

    if Cargo.config.targets then
        for _, v in ipairs(Cargo.config.targets) do
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
            elem["group_id"] = Cargo.config.group_id or nil
            elem["pre_hook"] = Cargo.config.pre_hook or nil
            elem["post_hook"] = Cargo.config.post_hook or nil

            table.insert(elements, elem)
        end
    end

    return elements
end

Cargo.health = function()
    if vim.fn.executable("cargo") == 1 then
        health.ok("`cargo`: Ok")
    else
        health.error("`cargo` requires cargo to be installed")
    end
end

---@class CargoOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field targets table?: Table with commands for cargo
---@field pre_hook function?: Function to run before running command. (default: nil)
---@field post_hook function?: Function to run after running command. (default: nil)
---
---@param config CargoOpts?: Configuration options
Cargo.setup = function(config)
    Cargo.config = config

    if not Cargo.config.targets then
        Cargo.config = {
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
end

return greyjoy.register_extension({
    setup = Cargo.setup,
    health = Cargo.health,
    exports = { type = "file", files = { "Cargo.toml" }, parse = Cargo.parse },
})
