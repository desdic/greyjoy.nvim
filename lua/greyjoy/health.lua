local health = vim.health
local extension_module = require("greyjoy._extensions")
local extension_info = require("greyjoy").extensions

local M = {}

M.check = function()
    health.start("Checking for optional plugins")

    local optional = { "toggleterm", "telescope", "plenary" }
    for _, plugin in pairs(optional) do
        local ok, _ = pcall(require, plugin)
        if not ok then
            health.warn("`" .. plugin .. "` not installed")
        else
            health.ok("`" .. plugin .. "` installed")
        end
    end

    health.start("===== Installed extensions =====")

    local installed = {}
    for extension_name, _ in pairs(extension_info) do
        installed[#installed + 1] = extension_name
    end
    table.sort(installed)

    for _, installed_ext in ipairs(installed) do
        local extension_healthcheck = extension_module._health[installed_ext]
        health.start(string.format("Greyjoy Extension: `%s`", installed_ext))
        if extension_healthcheck then
            extension_healthcheck()
        else
            health.info("No healthcheck provided")
        end
    end
end

return M
