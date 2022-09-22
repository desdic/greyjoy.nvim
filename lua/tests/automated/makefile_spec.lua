local utils = require("greyjoy.utils")
local eq = assert.are.same

describe("makefile extension", function()
    it("runs make", function()
        local makefile = require("greyjoy._extensions.makefile")

        eq(makefile.exports, utils.if_nil(makefile.exports, false))
        eq("file", utils.if_nil(makefile.exports.type, false))
        eq({"Makefile"}, utils.if_nil(makefile.exports.files, false))

        local makepath = vim.loop.cwd() .. "/lua/tests/automated/data"

        local fileobj = {}
        fileobj["filename"] = "Makefile"
        fileobj["filepath"] = makepath

        local res = makefile.exports.parse(fileobj)
        for _, case in ipairs({
            {name = "make all", path = makepath, command = "make all"},
            {name = "make build", path = makepath, command = "make build"}
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
