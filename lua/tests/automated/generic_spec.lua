local utils = require("greyjoy.utils")
local eq = assert.are.same

describe("makefile extension", function()
    it("runs make", function()
        local generic = require("greyjoy._extensions.generic")

        eq(generic.exports, utils.if_nil(generic.exports, false))

        local fileobj = {
            filename = "test.py",
            filetype = "python",
            filepath = "/home/example",
        }

        local config = {
            commands = {
                ["run test.py"] = {
                    command = { "./test.py" },
                    filetype = "python",
                    filename = "test.py",
                },
            },
        }

        generic.setup(config)
        local res = generic.exports.parse(fileobj)

        for _, case in ipairs({
            {
                name = "run test.py",
                path = "/home/example",
                command = "./test.py",
            },
        }) do
            local found = false

            for _, obj in ipairs(res) do
                if case.name == obj.name then
                    if case.path == obj.path then
                        local cmd = table.concat(obj.command, " ")
                        if case.command == cmd then
                            found = true
                        end
                    end
                end
            end

            it(case.name, function()
                eq(true, found)
            end)
        end
    end)
end)
