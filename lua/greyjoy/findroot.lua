local M = {}

local utils = require("greyjoy.utils")

local function get_parent(path)
    path = path:match("^(.*)/")
    if path == "" then path = "/" end
    return path
end

M.find = function(patterns, basepath)
    if not basepath then return nil end

    for _, pattern in ipairs(patterns) do
        if utils.file_exists(basepath .. "/" .. pattern) then
            return basepath
        end
    end

    if basepath == "/" then return nil end

    basepath = get_parent(basepath)

    return M.find(patterns, basepath)
end

return M
