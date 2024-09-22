---
--- The docker_compose extension scans the docker-compose.yml for targets
---
---@usage default configuration for the docker_compose extention
---
--- its triggered by the presence of docker-compose.yml
---
--- docker_compose = {
---   cmd = "/usr/bin/docker-compose", -- path to docker-compose
---   shell = "/bin/bash", -- shell when logging into a container
---   pre_hook = nil, -- run before executing command
---   post_hook = nil, -- run after executing command
--- }
---@tag docker_compose
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

local DockerCompose = {}

DockerCompose.parse = function(fileinfo)
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
        DockerCompose.config["cmd"]
            .. " -f "
            .. filename
            .. " ps --filter 'status=running' --format '{{.Service}}' 2>/dev/null"
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
            elem["command"] = {
                DockerCompose.config["cmd"],
                "exec",
                "-it",
                v,
                DockerCompose.config["shell"],
            }
            elem["path"] = filepath
            elem["plugin"] = "docker_compose"
            elem["group_id"] = DockerCompose.config.group_id or nil
            elem["pre_hook"] = DockerCompose.config.pre_hook or nil
            elem["post_hook"] = DockerCompose.config.post_hook or nil

            table.insert(elements, elem)
        end
    end

    return elements
end

DockerCompose.health = function()
    local cmd = DockerCompose.config["cmd"]:match("%S+")
    local basename = string.gsub(cmd, "(.*/)(.*)", "%2")
    if vim.fn.executable(basename) == 1 then
        health.ok("`" .. basename .. "`: Ok")
    else
        health.error(
            "`docker_compose` requires " .. basename .. " to be installed"
        )
    end
end

---@class DocerComposeOpts
---@field group_id number?: Toggleterm terminal group id. (default: nil)
---@field cmd string?: Path to docker-compose command. (default: /usr/bin/docker-compose)
---@field shell string?: Shell to use for login in container. (default: /bin/bash)
---@field pre_hook function?: Function to run before running command. (default: nil)
---@field post_hook function?: Function to run after running command. (default: nil)
---
---@param config DocerComposeOpts?: Configuration options
DockerCompose.setup = function(config)
    DockerCompose.config = config

    if not DockerCompose.config.cmd then
        DockerCompose.config["cmd"] = "/usr/bin/docker-compose"
    end
    if not DockerCompose.config.shell then
        DockerCompose.config["shell"] = "/bin/bash"
    end
end

return greyjoy.register_extension({
    setup = DockerCompose.setup,
    health = DockerCompose.health,
    exports = {
        type = "file",
        files = { "docker-compose.yml" },
        parse = DockerCompose.parse,
    },
})
