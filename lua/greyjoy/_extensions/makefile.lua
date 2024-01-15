local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
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
        print("[makefile] fileinfo must be a table")
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

            table.insert(elements, elem)
        end
    end

    return elements
end

M.health = function()
    if vim.fn.executable("make") == 1 then
        health.report_ok("`make`: Ok")
    else
        health.report_error("`makefile` requires make to be installed")
    end
    if vim.fn.executable("awk") == 1 then
        health.report_ok("`awk`: Ok")
    else
        health.report_error("`makefile` requires awk to be installed")
    end
end

return greyjoy.register_extension({
    setup = function(_) end,
    health = M.health,
    exports = { type = "file", files = { "Makefile" }, parse = M.parse },
})
