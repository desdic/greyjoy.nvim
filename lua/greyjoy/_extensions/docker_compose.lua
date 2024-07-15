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
        vim.log.levels.ERROR({ title = "Plugin error" })
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
            { title = "Greyjoy docker compose" }
        )
        return {}
    end

    local filename = fileinfo.filename
    local filepath = fileinfo.filepath
    local elements = {}

    local pipe = io.popen(
        M.config["cmd"]
            .. " -f "
            .. filename
            .. " ps --filter 'status=running' --format '{{.Service}}'"
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
            elem["name"] = "docker-compose exec " .. v
            elem["command"] =
                { M.config["cmd"], "exec", "-it", v, M.config["shell"] }
            elem["path"] = filepath
            elem["plugin"] = "docker_compose"

            if M.config["group_id"] then
                elem["group_id"] = M.config["group_id"]
            end

            table.insert(elements, elem)
        end
    end

    return elements
end

M.health = function()
    local cmd = M.config["cmd"]:match("%S+")
    local basename = string.gsub(cmd, "(.*/)(.*)", "%2")
    if vim.fn.executable(basename) == 1 then
        health.ok("`" .. basename .. "`: Ok")
    else
        health.error(
            "`docker_compose` requires " .. basename .. " to be installed"
        )
    end
end

M.setup = function(config)
    M.config = config

    if not M.config.cmd then
        M.config["cmd"] = "/usr/bin/docker-compose"
    end
    if not M.config.shell then
        M.config["shell"] = "/bin/bash"
    end

    M.config.include_all = utils.if_nil(M.config.include_all, false)
end

return greyjoy.register_extension({
    setup = M.setup,
    health = M.health,
    exports = {
        type = "file",
        files = { "docker-compose.yml" },
        parse = M.parse,
    },
})
