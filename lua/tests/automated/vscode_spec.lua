local utils = require("greyjoy.utils")
local eq = assert.are.same

describe("makefile extension", function()
    it("runs make", function()
        local vstasks = require("greyjoy._extensions.vscode_tasks")

        eq(vstasks.exports, utils.if_nil(vstasks.exports, false))
        eq("file", utils.if_nil(vstasks.exports.type, false))
        eq({".vscode/tasks.json"}, utils.if_nil(vstasks.exports.files, false))

        local taskpath = vim.loop.cwd() .. "/lua/tests/automated/data"

        local fileobj = {}
        fileobj["filename"] = ".vscode/tasks.json"
        fileobj["filepath"] = taskpath

        local res = vstasks.exports.parse(fileobj)

        for _, case in ipairs({
            {name = "echo", path = taskpath, command = "echo hello"},
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

            it(case.name, function() eq(true, found) end)
        end
    end)
end)
