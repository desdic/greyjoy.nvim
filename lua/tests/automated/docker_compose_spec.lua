local eq = assert.are.same

describe("docker_compose extension", function()
    it("reads config", function()
        local docker_compose = require("greyjoy._extensions.docker_compose")

        eq(docker_compose.exports, docker_compose.exports or false)

        local fileinfo = {
            filename = "docker-compose.yml",
            filepath = "/home/example",
        }

        local config = {
            cmd = "/usr/bin/docker-compose",
            shell = "/bin/bash",
        }

        docker_compose.setup(config)
        local res = docker_compose.exports.parse(fileinfo)

        -- Verify that parse returns a table
        eq(type(res), "table")
    end)

    it("validates fileinfo type", function()
        local docker_compose = require("greyjoy._extensions.docker_compose")

        local config = {}
        docker_compose.setup(config)

        -- Test with invalid input
        local res = docker_compose.exports.parse("not a table")
        eq(type(res), "table")
        eq(#res, 0)
    end)
end)
