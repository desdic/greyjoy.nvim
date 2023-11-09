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

local M = {}

M.parse_v2 = function(content, filepath)
    if not content["tasks"] then
        return {}
    end

    local filecommands = {}

    for _, v in pairs(content["tasks"]) do
        if v["type"] and v["type"] == "shell" then
            if v["label"] and v["command"] then
                local elem = {}
                elem["name"] = v["label"]
                elem["command"] = { v["command"] }
                elem["path"] = filepath

                if v["args"] then
                    for _, value in pairs(v["args"]) do
                        table.insert(elem["command"], value)
                    end
                end

                table.insert(filecommands, elem)
            end
        end
    end

    return filecommands
end

M.read = function(filename)
    local fd = io.open(filename, "r")
    if not fd then
        return nil
    end

    local content = fd:read("*a")

    fd:close()

    local jsoncontent = vim.fn.json_decode(content)
    if not jsoncontent then
        return nil
    end

    return jsoncontent
end

M.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        print("[vscode_tasks] fileinfo must be a table")
        return {}
    end

    local filename = fileinfo.filename
    local filepath = fileinfo.filepath

    local content = M.read(filepath .. "/" .. filename)
    if not content then
        return {}
    end

    local major, _, _ = string.match(content["version"], "(%d+)%.(%d+)%.(%d+)")

    if tonumber(major) ~= 2 then
        return {}
    end

    return M.parse_v2(content, filepath)
end

return greyjoy.register_extension({
    setup = function(_) end,
    exports = { type = "file", files = { ".vscode/tasks.json" }, parse = M.parse },
})
