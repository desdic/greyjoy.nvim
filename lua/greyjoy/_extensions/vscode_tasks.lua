---
--- The vscode_tasks extension looks for tasks defined in tasks.json
---
---@usage default configuration for the vscode_tasks
---
--- its triggered by the presence of .vscode/tasks.json
---
--- > lua
--- vscode_tasks = {
---   group_id = nil, -- group id for toggleterm
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---
---@tag greyjoy.vscode_tasks

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

local VSCodeTask = {}

VSCodeTask.parse_v2 = function(content, filepath)
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
                elem["plugin"] = "vscode_tasks"
                elem["group_id"] = VSCodeTask.config.group_id or nil
                elem["pre_hook"] = VSCodeTask.config.pre_hook or nil
                elem["post_hook"] = VSCodeTask.config.post_hook or nil

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

VSCodeTask.read = function(filename)
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

VSCodeTask.parse = function(fileinfo)
    if type(fileinfo) ~= "table" then
        vim.notify(
            "fileinfo must be a table",
            vim.log.levels.ERROR,
            { title = "Greyjoy vscode_tasks" }
        )
        return {}
    end

    local filename = fileinfo.filename
    local filepath = fileinfo.filepath

    local content = VSCodeTask.read(filepath .. "/" .. filename)
    if not content then
        return {}
    end

    local major, _, _ = string.match(content["version"], "(%d+)%.(%d+)%.(%d+)")

    if tonumber(major) ~= 2 then
        return {}
    end

    return VSCodeTask.parse_v2(content, filepath)
end

---@class VSCodeTasksOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field pre_hook function?: Function to run before running command. (default: nil)
---@field post_hook function?: Function to run after running command. (default: nil)
---
---@param config VSCodeTasksOpts?: Configuration options
VSCodeTask.setup = function(config)
    VSCodeTask.config = config
end

return greyjoy.register_extension({
    setup = VSCodeTask.setup,
    exports = {
        type = "file",
        files = { ".vscode/tasks.json" },
        parse = VSCodeTask.parse,
    },
})
