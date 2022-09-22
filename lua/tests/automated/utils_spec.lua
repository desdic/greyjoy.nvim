local utils = require("greyjoy.utils")
local eq = assert.are.same

describe("utils", function()
    it("file exists", function()
        local thisfile = vim.loop.cwd() ..
                             "/lua/tests/automated/utils_spec.lua"

        eq(true, utils.file_exists(thisfile))
        eq(false, utils.file_exists(thisfile .. ".bak"))
    end)

    it("output of basename", function()
        eq("myfile", utils.basename("/home/myuser/myfile"))
        eq("my file", utils.basename("/home/my user/my file"))
        eq("my file", utils.basename("/home/my user/my file"))
    end)
    it("output of dirname", function()
        eq("/home/myuser/", utils.dirname("/home/myuser/myfile"))
        eq("/home/my user/", utils.dirname("/home/my user/my file"))
    end)
    it("is_match", function()
        local filename = "test.py"
        local filetype = "python"
        local filepath = "/home/mytest/"

        for _, case in ipairs({
            {name = "empty", input = {}, expected = true},
            {
                name = "filename#1",
                input = {filename = "test.py"},
                expected = true
            },
            {
                name = "filename#2",
                input = {filename = "testing.py"},
                expected = false
            },
            {
                name = "filetype#1",
                input = {filetype = "python"},
                expected = true
            },
            {name = "filetype#2", input = {filetype = "go"}, expected = false},
            {
                name = "filepath#1",
                input = {filepath = "/home/mytest/"},
                expected = true
            },
            {
                name = "filepath#2",
                input = {filepath = "/home/my test/"},
                expected = false
            }, {
                name = "combo#1",
                input = {filename = "test.py", filepath = "/home/mytest/"},
                expected = true
            }, {
                name = "combo#2",
                input = {
                    filename = "test.py",
                    filetype = "python",
                    filepath = "/home/mytest/"
                },
                expected = true
            }
        }) do
            it(case.name, function()
                eq(case.expected,
                   utils.is_match(case.input, filename, filetype, filepath))
            end)
        end
    end)
    it("if_nil", function()
        for _, case in ipairs({
            {name = "noinput", input = nil, expected = true},
            {name = "true", input = true, expected = true},
            {name = "false", input = false, expected = false},
            {name = "hello", input = "hello", expected = "hello"}
        }) do
            it(case.name,
               function()
                eq(case.expected, utils.if_nil(case.input, true))
            end)
        end
    end)
end)
