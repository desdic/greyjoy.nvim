-- Defaults
local defaults = {
	enable = true, -- enable/disable plugin
	border = "rounded", -- default borders
	style = "minimal", -- default style
	show_command = false, -- show full command when selection
	show_command_in_output = true, -- Show the command that was running in output
	patterns = {".git", ".svn"},
	extensions = {},
}

-- Set/Change options
local function set(_, key, value)
	defaults[key] = value
end

-- Get options
local function get(_, key)
	return defaults[key]
end

return {
	defaults = defaults,
	get = get,
	set = set,
}