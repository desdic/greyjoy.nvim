local M = {}

local greyutil = require("greyjoy.utils")

M.file_exists = function(filename, obj)
    local fpath = vim.fs.joinpath(obj.rootdir, filename)
    if greyutil.file_exists(fpath) then
        return true
    end
end

M.directory_exists = function(dirname, obj)
    print(vim.inspect(dirname))
    local fpath = vim.fs.joinpath(obj.rootdir, dirname)
    if greyutil.directory_exists(fpath) then
        return true
    end
end

return M
