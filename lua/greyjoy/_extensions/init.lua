local extensions = {}

extensions._loaded = {}
extensions._config = {}

local load_extension = function(name)
    local ok, ext = pcall(require, "greyjoy._extensions." .. name)
    if not ok then
        vim.notify("Unable to require greyjoy._extensions." .. name,
                   vim.lsp.log_levels.ERROR, {title = "Plugin error"})
        return
    end
    return ext
end

extensions.manager = setmetatable({}, {
    __index = function(t, k)
        local ext = load_extension(k)
        t[k] = ext.exports or {}
        if ext.setup then
			ext.setup(extensions._config[k] or {})
        end

        return t[k]
    end
})

extensions.register = function(mod) return mod end

extensions.load = function(name)
    local ext = load_extension(name)
 --    if ext.setup then 
	-- 	ext.setup(extensions._config[name] or {})
	-- end

    return extensions.manager[name]
end

extensions.set_config = function(config)
	extensions._config = config or {}
end

return extensions
