local M = {}

M.file_exists = function(filename)
    return vim.fn.filereadable(filename) ~= 0
end

M.is_match = function(v, filename, filetype, filepath)
    if v.filename then
        if v.filename ~= filename then
            return false
        end
    end

    if v.filetype then
        if v.filetype ~= filetype then
            return false
        end
    end

    if v.filepath then
        if not string.find(filepath, v.filepath) then
            return false
        end
    end

    return true
end

M.if_nil = function(x, y)
    if x == nil then
        return y
    end
    return x
end

M.str_to_array = function(str)
    local words = {}
    for word in str:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

return M
