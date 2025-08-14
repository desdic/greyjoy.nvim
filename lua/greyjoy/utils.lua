local M = {}

M.file_exists = function(filename)
    return vim.fn.filereadable(filename) ~= 0
end

M.directory_exists = function(dirname)
    return vim.fn.isdirectory(dirname) ~= 0
end

M.is_match = function(obj, filename, filetype, filepath, rootdir)
    if obj.filename then
        if obj.filename ~= filename then
            return false
        end
    end

    if obj.filetype then
        if obj.filetype ~= filetype then
            return false
        end
    end

    if obj.filepath then
        if not string.find(filepath, obj.filepath) then
            return false
        end
    end

    if obj.condition then
        if type(obj.condition) == "function" then
            return obj.condition({
                obj = obj,
                filename = filename,
                filetype = filetype,
                filepath = filepath,
                rootdir = rootdir,
            })
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

M.new_file_obj = function(patterns, bufname, filetype)
    local fullname = bufname
    local filename = vim.fs.basename(bufname)
    local filepath = vim.fs.dirname(bufname)

    filepath = M.if_nil(filepath, "")
    if filepath == "" then
        filepath = vim.uv.cwd()
    end

    local rootdir = vim.fs.dirname(vim.fs.find(patterns, { upward = true })[1])
    rootdir = M.if_nil(rootdir, filepath)

    return {
        filetype = filetype,
        fullname = fullname,
        filename = filename,
        filepath = filepath,
        rootdir = rootdir,
    }
end

M.substitute_variables = function(value, fileobj)
    local command = {}
    if type(value) == "table" then
        for index in ipairs(value) do
            local celem = value[index]
            celem = celem:gsub("{filename}", fileobj.filename)
            celem = celem:gsub("{filepath}", fileobj.filepath)
            celem = celem:gsub("{rootdir}", fileobj.rootdir)

            table.insert(command, celem)
        end
    elseif type(value) == "string" then
        value = value:gsub("{filename}", fileobj.filename)
        value = value:gsub("{filepath}", fileobj.filepath)
        value = value:gsub("{rootdir}", fileobj.rootdir)
        command = { value }
    end
    return command
end

return M
