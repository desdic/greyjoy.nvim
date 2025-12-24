local eq = assert.are.same
local conditions = require("greyjoy.conditions")

describe("conditions module", function()
    it("provides file_exists function", function()
        eq(type(conditions.file_exists), "function")
    end)

    it("provides directory_exists function", function()
        eq(type(conditions.directory_exists), "function")
    end)

    it("file_exists returns boolean", function()
        local fileobj = {
            rootdir = "/tmp",
        }
        local result = conditions.file_exists("nonexistent_file_xyz.txt", fileobj)
        eq(type(result), "boolean")
        eq(result, false)
    end)

    it("directory_exists returns boolean", function()
        local fileobj = {
            rootdir = "/tmp",
        }
        local result = conditions.directory_exists("nonexistent_dir_xyz", fileobj)
        eq(type(result), "boolean")
        eq(result, false)
    end)
end)
