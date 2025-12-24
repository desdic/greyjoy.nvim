local eq = assert.are.same

describe("cargo extension", function()
    it("reads config", function()
        local cargo = require("greyjoy._extensions.cargo")

        eq(cargo.exports, cargo.exports or false)

        local fileinfo = {
            filename = "Cargo.toml",
            filepath = "/home/example",
        }

        local config = {}

        cargo.setup(config)
        local res = cargo.exports.parse(fileinfo)

        -- Verify that parse returns a table
        eq(type(res), "table")
    end)

    it("validates fileinfo type", function()
        local cargo = require("greyjoy._extensions.cargo")

        local config = {}
        cargo.setup(config)

        -- Test with invalid input
        local res = cargo.exports.parse("not a table")
        eq(type(res), "table")
        eq(#res, 0)
    end)
end)
