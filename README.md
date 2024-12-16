# greyjoy.nvim

![Test](https://github.com/desdic/greyjoy.nvim/actions/workflows/ci.yml/badge.svg)

## What is greyjoy

`greyjoy.nvim` is a pluggable pattern/file based launcher/runner.

[![Greyjoy.nvim demo](http://img.youtube.com/vi/9AcNjkqROIM/0.jpg)](http://www.youtube.com/watch?v=9AcNjkqROIM "Greyjoy.nvim demo")

Greyjoy per default uses vim.ui.select so the settings from (telescope, dressing etc.) menu will reflect it. But there is also support for telescope (requires [telescope](https://github.com/nvim-telescope/telescope.nvim)) and a fzf (requires [fzf-lua](https://github.com/ibhagwan/fzf-lua))

Integration with [toggleterm](https://github.com/akinsho/toggleterm.nvim) is also provided.

## Requirements

Neovim 0.10+ is required

[Toggleterm](https://github.com/akinsho/toggleterm.nvim) (Optional)

[Telescope](https://github.com/nvim-telescope/telescope.nvim) + [Plenary](https://github.com/nvim-lua/plenary.nvim) (Optional but UI is more responsive)

[Fzf-lua](https://github.com/ibhagwan/fzf-lua) (Optional)

## Installing

Using lazy (A more comprehensive example can be found in the [documentation](doc/greyjoy.txt))

```
{
    "desdic/greyjoy.nvim",
    keys = {
        { "<Leader>gr", "<cmd>Greyjoy<CR>", desc = "[G]reyjoy [r]un" },
        { "<Leader>gt", "<cmd>GreyjoyTelescope<CR>", desc = "[G]reyjoy [t]elescope" },
        { "<Leader>gg", "<cmd>GreyjoyFzf fast<CR>", desc = "[G]reyjoy fast [g]roup" },
        { "<Leader>ge", "<cmd>Greyedit<CR>", desc = "[G]reyjoy [e]edit before run" },
    },
    dependencies = {
        { "akinsho/toggleterm.nvim" }, -- Optional
        { "nvim-lua/plenary.nvim" }, -- Optional
        { "nvim-telescope/telescope.nvim" }, -- Optional
    },
    cmd = { "Greyjoy", "Greyedit", "GreyjoyTelescope", "GreyjoyFzf" },
    config = function()
        local greyjoy = require("greyjoy")
        local condition = require("greyjoy.conditions")
        greyjoy.setup({
            output_results = require("greyjoy.terminals").term,
            -- output_results = require("greyjoy.terminals").toggleterm,
            last_first = true,
            extensions = {
                generic = {
                    commands = {
                        ["run {filename}"] = { command = { "python3", "{filename}" }, filetype = "python" },
                        ["build main.go"] = {
                            command = { "go", "build", "main.go" },
                            filetype = "go",
                            filename = "main.go",
                        },
                        ["zig build"] = {
                            command = { "zig", "build" },
                            filetype = "zig",
                        },
                        ["cmake -S . -B target"] = {
                            command = { "cmake", "-S", ".", "-B", "target" },
                            condition = function(n)
                                return condition.file_exists("CMakeLists.txt", n)
                                    and not condition.directory_exists("target", n)
                            end,
                        },
                    },
                },
                kitchen = { group_id = 2, targets = { "converge", "verify", "destroy", "test" }, include_all = false },
                docker_compose = { group_id = 3 },
                cargo = { group_id = 4 },
            },
            run_groups = { fast = { "generic", "makefile", "cargo", "docker_compose" } },
        })

        greyjoy.load_extension("cargo") -- optional
        greyjoy.load_extension("docker_compose") -- optional
        greyjoy.load_extension("generic") -- optional
        greyjoy.load_extension("kitchen") -- optional
        greyjoy.load_extension("makefile") -- optional
        greyjoy.load_extension("vscode_tasks") -- optional
    end,
}
```

Once installed and reloaded you can use `:Greyjoy` or `:GreyjoyTelescope` to run it or `Greyjoy/GreyjoyTelescope <pluginname or group name>`. If you need to edit a command (like adding a variable or option) you can use `:Greyedit` (Works with group and plugins as parameter too).

So in the above example its possible to run the generic and makefile plugin by running `:Greyjoy fast` or if you only wanted to run the makefile plugin you could do `:Greyjoy makefile`

## Default settings

```
{
  ui = {
    buffer = { -- width and height for the buffer output
      width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20))),
      height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10))),
    },
    toggleterm = { -- by default no size is defined for the toggleterm by
      -- greyjoy.nvim it will be dependent on the user configured size for toggle
      -- term.
      size = nil,
    },
    term = {
      height = 5,
    },
    telescope = {
        keys = {
            select = "<CR>", -- enter
            edit = "<C-e>", -- CTRL-e
        },
    }
  },
  toggleterm = {
      -- default_group_id can be a number or a function that takes a string as parameter.
      -- The string passed as parameter is the name of the plugin so its possible to do logic based
      -- on plugin name and function should always return a number like:
      -- default_group_id = function(plugin) return 1 end
      default_group_id = 1,
  },
  enable = true,
  border = "rounded", -- style for vim.ui.selector
  style = "minimal",
  show_command = false, -- show command to run in menu
  show_command_in_output = true, -- show command that was just executed in output
  patterns = {".git", ".svn"}, -- patterns to find the root of the project
  output_result = "buffer", -- buffer or to toggleterm
  extensions = {}, -- no extensions are loaded per default
  last_first = false, -- make sure last option is first on next run, not persistant
  run_groups = {}, -- no groups configured per default
  overrides = {}, -- make global overrides
}
```

Per default all plugins use the same terminal but this behaviour (if you are using `toggleterm`) can be overridden by either grouping the plugins to a specific `group_id` or create a function to assign number based on plugin name.

So if you want all plugins to run under id `id` (default) but the `docker_compose` you would like to have another group you can configure it via

```
  extensions = {
    docker_compose = { group_id = 2 },
  },
```

and now all docker compose's exec is running in a secondary terminal (group_id 2) and all the others in group_id 1

## Extensions

Default `greyjoy` does not have any extensions enabled.

### Generic

`generic` extension is a global module that does not take into account if we are in a project (found via the patterns). Commands to run can be matched using `filetype`, `filename`, `filepath`

example:
```
generic = {
  commands = {
    ["run {filename}"] = {
      command = {"python3", "{filename}"},
      filetype = "python",
      filename = "test.py"
    },
    ["run {filename}"] = {
      command = {"go", "run", "{filename}"},
      filetype = "go"
    },
    ["cmake --build target"] = {
        command = { "cd", "{rootdir}", "&&", "cmake", "--build", "{rootdir}/target" },
        condition = function(n)
            return condition.file_exists("CMakeLists.txt", n)
                and condition.directory_exists("target", n)
        end,
    },
    ["cmake -S . -B target"] = {
        command = { "cd", "{rootdir}", "&&", "cmake", "-S", ".", "-B", "{rootdir}/target" },
        condition = function(n)
            return condition.file_exists("CMakeLists.txt", n)
                and not condition.directory_exists("target", n)
        end,
    },
    ...
  }
},
```

The generic module can substitute current variables

| variable | expands to |
| :--- | :--- |
| {filename} | current filename |
| {filepath} | path of current file |
| {rootdir} | path of root (containing patterns like .git) |

The above example is only triggered if a file is of type `python` and the filename matches `test.py`

### Makefile

The `makefile` extension is filebased and will only trigger if a `Makefile` is located in the project root. It finds all targets for a `Makefile`.

requires `make` and `awk` to work.

### Vscode_tasks

The `vscode_tasks` extension is filebased and will only trigger if `.vscode/tasks.json` exists in the project root

### Kitchen

The `kitchen` extension is also filebased and looks for `.kitchen.yml` and requires `kitchen` (from chefdk or cinc-workstation) + `awk` to be installed.

NOTICE: kitchen is quite slow so its possible to create a group without it and only use it when needed

### Cargo

The `cargo` extension is filebased and looks for `Cargo.toml` and requires `cargo`

### Docker_compose

The `docker_compose` extension is filebased and looks for `docker-compose.yml` and requires `docker-compose`/`docker compose`

## Documentation

Full configuration options and examples can be found in the [documentation](doc/greyjoy.txt)

## Checkhealth

Once installed make sure you run `:checkhealth greyjoy` to ensure its set up correctly.

## Breaking changes

Breaking changes will be announced in this [Github Issue](https://github.com/desdic/greyjoy.nvim/issues/1)

## Development

* Source hosted at [github](https://github.com/desdic/greyjoy.nvim)
* Report issues/questions/feature requests on [GitHub Issues](https://github.com/desdic/greyjoy.nvim/issues/)

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Thank you / shout-outs

* The extension in this module is heavily inspired by the manager in [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Credits

Thanks to 

@TheSafdarAwan for PR #22

@costowell for PR #32
