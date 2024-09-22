---
--- The makefile extension scans the makefile for targets
---
---@usage default configuration for the makefile extention
---
--- makefile = {
---   group_id = nil, -- group id for toggleterm
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---@tag makefile
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

local Makefile = {}

Makefile.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy makefile" }
        )
        return {}
    end

    local filename = fileinfo.filename
    local filepath = fileinfo.filepath
    local elements = {}

    local pipe = io.popen(
        "make -pRrq -f "
            .. filename
            .. " -C "
            .. filepath
            .. [[ : 2>/dev/null |
                awk -F: '/^# Files/,/^# Finished Make data base/ {
                    if ($1 == "# Not a target") skip = 1;
                    if ($1 !~ "^[#.\t]") { if (!skip) {if ($1 !~ "^$")print $1}; skip=0 }
                }' 2>/dev/null]]
    )

    if not pipe then
        return elements
    end

    local data = pipe:read("*a")
    io.close(pipe)

    if #data == 0 then
        return elements
    end

    local tmp = vim.split(string.sub(data, 1, #data - 1), "\n")
    for _, v in ipairs(tmp) do
        if v ~= "" then
            local elem = {}
            elem["name"] = "make " .. v
            elem["command"] = { "make", v }
            elem["path"] = filepath
            elem["plugin"] = "makefile"
            elem["group_id"] = Makefile.config.group_id or nil
            elem["pre_hook"] = Makefile.config.pre_hook or nil
            elem["post_hook"] = Makefile.config.post_hook or nil

            table.insert(elements, elem)
        end
    end

    return elements
end

---@class MakefileOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field pre_hook function?: Function to run before running command
---@field post_hook function?: Function to run after running command
---
---@param config MakefileOpts?: Configuration options
Makefile.setup = function(config)
    Makefile.config = config
end

Makefile.health = function()
    if vim.fn.executable("make") == 1 then
        health.ok("`make`: Ok")
    else
        health.error("`makefile` requires make to be installed")
    end
    if vim.fn.executable("awk") == 1 then
        health.ok("`awk`: Ok")
    else
        health.error("`makefile` requires awk to be installed")
    end
end

return greyjoy.register_extension({
    setup = Makefile.setup,
    health = Makefile.health,
    exports = { type = "file", files = { "Makefile" }, parse = Makefile.parse },
})
