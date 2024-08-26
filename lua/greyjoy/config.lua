-- Defaults
local defaults = {
    ui = {
        buffer = { -- setting for buffer output
            width = math.ceil(
                math.min(vim.o.columns, math.max(80, vim.o.columns - 20))
            ),
            height = math.ceil(
                math.min(vim.o.lines, math.max(20, vim.o.lines - 10))
            ),
        },
        toggleterm = { -- by default no size is defined for the toggleterm by
            -- greyjoy.nvim it will be dependent on the user configured size for toggle
            -- term.
            size = nil,
        },
        telescope = {
            keys = {
                select = "<CR>", -- enter
                edit = "<C-e>", -- CTRL-e
            },
        },
    },
    toggleterm = {
        -- default_group_id can be a number or a function that takes a string as parameter.
        -- The string passed as parameter is the name of the plugin so its possible to do logic based
        -- on plugin name and function should always return a number like:
        -- default_group_id = function(plugin) return 1 end
        default_group_id = 1,
    },
    enable = true, -- enable/disable plugin
    border = "rounded", -- default borders
    style = "minimal", -- default style
    show_command = false, -- show full command when selection
    show_command_in_output = true, -- Show the command that was running in output
    patterns = { ".git", ".svn" },
    output_result = "buffer",
    default_shell = vim.o.shell, -- default shell to run tasks in
    extensions = {},
    last_first = false, -- make sure last option is first on next run, not persistant
    overrides = {}, -- make global overrides
}

-- Set/Change options
local function set(_, key, value)
    defaults[key] = value
end

-- Get options
local function get(_, key)
    return defaults[key]
end

return { defaults = defaults, get = get, set = set }
