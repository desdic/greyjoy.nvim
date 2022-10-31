local M = {}

M.file_exists = function(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

M.is_match = function(v, filename, filetype, filepath)
    if v.filename then if v.filename ~= filename then return false end end

    if v.filetype then if v.filetype ~= filetype then return false end end

    if v.filepath then
        if not string.find(filepath, v.filepath) then return false end
    end

    return true
end

M.if_nil = function(x, y)
    if x == nil then return y end
    return x
end

return M
