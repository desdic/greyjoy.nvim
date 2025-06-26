---
--- Condition helper functions
---
---@tag conditions
local Conditions = {}

local greyutil = require("greyjoy.utils")

---@param filename string Filename to look for
---@param obj table Fileobject passed down from condition function
---@return boolean
---
---@usage `require("greyjoy.conditions").file_exists("CMakeLists.txt", fileobj)`
---
Conditions.file_exists = function(filename, obj)
    local fpath = vim.fs.joinpath(obj.rootdir, filename)
    if greyutil.file_exists(fpath) then
        return true
    end
    return false
end

---@param dirname string Dirname to look for
---@param obj table Fileobject passed down from condition function
---@return boolean
---
---@usage `require("greyjoy.conditions").directory_exists("mybindir", fileobj)`
---
Conditions.directory_exists = function(dirname, obj)
    local fpath = vim.fs.joinpath(obj.rootdir, dirname)
    if greyutil.directory_exists(fpath) then
        return true
    end
    return false
end

return Conditions
