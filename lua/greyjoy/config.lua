-- Defaults
local defaults = {
    ui = {
      buffer = { -- setting for buffer output
        width = 100,
        height = 60,
      },
      toggleterm = { -- by default no size is defined for the toggleterm by
        -- greyjoy.nvim it will be dependent on the user configured size for toggle
        -- term.
        size = nil
      },
    },
    enable = true, -- enable/disable plugin
    border = "rounded", -- default borders
    style = "minimal", -- default style
    show_command = false, -- show full command when selection
    show_command_in_output = true, -- Show the command that was running in output
    patterns = {".git", ".svn"},
    output_result = "buffer",
    extensions = {},
    last_first = false -- make sure last option is first on next run, not persistant
}

-- Set/Change options
local function set(_, key, value) defaults[key] = value end

-- Get options
local function get(_, key) return defaults[key] end

return {defaults = defaults, get = get, set = set}
