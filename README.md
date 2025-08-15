# 🚀 `greyjoy.nvim`

![Test](https://github.com/desdic/greyjoy.nvim/actions/workflows/ci.yml/badge.svg)

`greyjoy.nvim` is a highly extensible and pluggable pattern/file based launcher/runner.

## ⚡️ Requirements

**Neovim** >=0.11

## 📦 Installation

Install the plugin with your package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

> [!important]
> Greyjoy is pluggable and has no default extensions so in order run anything you need at least one extension enabled
> Check the [extensions](#extensions) section.

> [!tip]
> It's a good idea to run `:checkhealth greyjoy` to see if everything is set up correctly.

Basic example using the [generic](#generic) plugin to get started

```lua
{
    "desdic/greyjoy.nvim",
    config = function()
        greyjoy.setup({
            extensions = {
                generic = {
                    commands = {
                        ["run {filename}"] = { command = { "python3 {filename}" }, filetype = "python" },
                    },
                },
            },
        })

        greyjoy.load_extension("generic")
    end
}
```

Once installed and reloaded you can use

| Command | Description | Requires |
| --- | :--- | :--- |
| `:Greyjoy` <optional extension name or group name>  | Show run list | None |
| `:Greyjoyedit` <optinal extension name or group name> | Edit command from run list (only persist during session) | None |
| `:GreyjoyRunLast` | Run last command  | None |
| `:GreyjoyTelescope` <optional extension name or group name>  | Show/Edit run list | Telescope |
| `:GreyjoyFzf` <optional extension name or group name>  | Show/Edit run list | Fzf-lua |

<details><summary>Optional dependencies</summary>

<br/>

Greyjoy uses `vim.ui.select` and built-in terminal/buffers but integration with a few plugins are available but requires dependencies

|Plugin|
|--- |
|[Toggleterm](https://github.com/akinsho/toggleterm.nvim)|
|[Telescope](https://github.com/nvim-telescope/telescope.nvim)|
|[Fzf-lua](https://github.com/ibhagwan/fzf-lua)|

Available when installed.

</details>

## ⚙️ Configuration

<details><summary>Default options</summary>

<br/>

```lua
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
      width_pct = 0.2, -- 20% of screen
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
  output_result = require("greyjoy.terminals").buffer,
  extensions = {}, -- extensions configurations
  run_groups = {}, -- See `Run groups`
  overrides = {}, -- Stores internal overrides of commands
}
```

Per default all plugins use the same terminal/buffer but this behaviour can be overridden if you are using `toggleterm`.

Toggleterm supports multiple terminals so you can group extensions into having different terminal.

Specify `group_id` or create a function to assign number based on plugin name.

So if you want all extensions to run under `id` 1 (default) but the `docker_compose` you would like to have another group you can configure it via

```
  extensions = {
    docker_compose = { group_id = 2 },
  },
```

Now all docker compose's exec is running in a secondary terminal (group_id 2) and all the others in group_id 1

### 🫂 Run groups

Some extension can be slow or not always required so its possible to group extensions into groups.

```lua
{
	...
     run_groups = { fast = { "generic", "makefile", "cargo", "docker_compose" } },
	...
}
```

Invoking `:Greyjoy fast` now only runs the defined extensions.

### 🪝 Hooks

Hooks can be invoked before and after a command and no default ones are defined.

An example of running a target via a makefile can put the errors in the quickfix list just like running it via the `:make`:

```lua
return {
    "desdic/greyjoy.nvim",
    keys = {
        { "<leader>gr", "<cmd>Greyjoy<CR>", desc = "[G]reyjoy [r]un" },
    },
    cmd = { "Greyjoy", "Greyedit", "GreyjoyRunLast" },
    config = function()
        local greyjoy = require("greyjoy")

        local tmpmakename = nil

        local pre_make = function(command)
            tmpmakename = os.tmpname()
            table.insert(command.command, "2>&1")
            table.insert(command.command, "|")
            table.insert(command.command, "tee")
            table.insert(command.command, tmpmakename)
        end

        -- A bit hacky solution to checking when tee has flushed its file
        local post_make = function()
            vim.cmd(":cexpr []")
            local cmd = { "inotifywait", "-e", "close_write", tmpmakename }

            local job_id = vim.fn.jobstart(cmd, {
                stdout_buffered = true,
                on_exit = function(_, _, _)
                    if tmpmakename ~= nil then
                        vim.cmd(":cgetfile " .. tmpmakename)
                        os.remove(tmpmakename)
                    end
                end,
            })

            if job_id <= 0 then
                vim.notify("Failed to start inotifywait!")
            end
        end

        greyjoy.setup({
            ui = {
                term = {
                    height = 10,
                },
            },
            output_results = require("greyjoy.terminals").term,
            extensions = {
                makefile = {
                    pre_hook = pre_make,
                    post_hook = post_make,
                },
            }
        })

        greyjoy.load_extension("makefile")
    end,
}
```

</details>


## ✨ Extensions
<a id="extensions"></a>

Two types of extensions are currently supported. `global` always runs and `file` will only run on specific files being present.

<!-- toc:start -->

| Plugin | Type | Description |
| ----- | --- | :--- |
| [Generic](#generic) | global |Handles condition based running of commands  |
| [File](#file) | global |Handles running command bases on configuration file per project  |
| [Makefile](#makefile) | file | Parses makefile and lists targets and runable  |
| [vscode_tasks](#vscode_tasks) | file | Parses vscode tasks file  |
| [kitchen](#kitchen) | file | Handles kitchen targets  |
| [cargo](#cargo) | file | Gives a default run list when `Cargo.toml` is available |
| [docker_compose](#docker_compose) | file | List docker compose targets as runable  |

<!-- toc:end -->

<details><summary>Generic extension</summary>
<a id="generic"></a>

### Generic extension

`generic` extension is a global module that does not take into account if we are in a project (found via the patterns). Commands to run can be matched using `filetype`, `filename`, `filepath`

Example:
```
generic = {
  commands = {
    ["run {filename}"] = {
      command = {"python3 {filename}"}, -- can be a single string or multiple but is still a single command
      filetype = "python", -- only runs if filetype is python and filename is test.py
      filename = "test.py"
    },
    ["run {filename}"] = {
      command = {"go", "run", "{filename}"},
      filetype = "go" -- run if filetype is go
    },
    ["cmake --build target"] = {
        command = { "cd", "{rootdir}", "&&", "cmake", "--build", "{rootdir}/target" },
        condition = function(n) -- custom conditions can be added
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
</details>

<details><summary>File extension</summary>
<a id="file"></a>

### File extension

`file` extension is a global module that only reads `greyjoy.json` (can be changed) from within your project

Example configuration:
```
file = {
  filename = "myrunner.json"
},
```
The configuration file is a simple key value. Value can be a string or an array (same result).

```json
{
  "build all": ["make", "build"],
  "do cleanup": "make clean"
}

```

</details>

<details><summary>Makefile extension</summary>
<a id="makefile"></a>

### Makefile extension

The `makefile` extension is file based and will only trigger if a `Makefile` is located in the project root. It finds all targets for a `Makefile`.

> [!important]
> requires `make` and `awk` to work.

</details>

<details><summary>Vscode_tasks extension</summary>
<a id="vscode_tasks"></a>
<br/>

### Vscode_tasks extension

The `vscode_tasks` extension is file based and will only trigger if `.vscode/tasks.json` exists in the project root
</details>

<details><summary>Kitchen extension</summary>
<a id="kitchen"></a>

### Kitchen extension

> [!important]
> requires `kitchen` and `awk` to work.

> [!tip]
> kitchen is quite slow so its possible to create a group without it and only use it when needed.

The `kitchen` extension is also file based and looks for `.kitchen.yml` (chefdk or cinc-workstation).

This extension can be configured to only include specific targets

```lua
extensions = {
    kitchen = {
        targets = { "converge", "verify", "destroy", "test", "login" },
        include_all = false,
    }
}
```

</details>

<details><summary>Cargo extension</summary>
<a id="cargo"></a>

### Cargo extension

The `cargo` extension is file based and looks for `Cargo.toml` and requires `cargo`

> [!important]
> requires `cargo`.

</details>

<details><summary>Docker_compose extension</summary>
<a id="docker_compose"></a>
<br/>

### Docker_compose extension

The `docker_compose` extension is file based and looks for `docker-compose.yml`.

> [!important]
> requires `docker-compose` or `docker compose`.

</details>

## 🧩 Variables

Simple substitutions can be use to make more specific runners

| variable | expands to |
| :--- | :--- |
| {filename} | current filename |
| {filepath} | path of current file |
| {rootdir} | path of root (configured via patterns in config)  |

## 🤝 Helper functions

<details><summary>🤳 Conditions</summary> 
<a id="conditions"></a>

Condition functions can be applied to the `generic` extension in case the built-in isn't enough.

<!-- toc:start -->

| Function | Description |
| :--- | :--- |
| require("greyjoy.conditions").file_exists | Check if file exists |
| require("greyjoy.conditions").directory_exists | Check if directory exists |

<!-- toc:end -->

</details>

<details><summary>🖥️ Terminal/Buffers</summary>
<a id="terminals"></a>
<br/>

Displaying the output of a command is based on the function defined in `output_result`. Default it just outputs to a buffer but you can write a function for your custom need.

<!-- toc:start -->

| Function | Description |
| :--- | :--- |
| require("greyjoy.terminals").buffer | Default, outputs into a buffer |
| require("greyjoy.terminals").term | Opens a terminal in the bottom |
| require("greyjoy.terminals").toggleterm | Use toggleterm (requires [toggleterm](https://github.com/akinsho/toggleterm.nvim)) |

<!-- toc:end -->

</details>

## 📚 Documentation

Documentation and a more comprehensive example can be found in the [documentation](doc/greyjoy.txt)

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

## Thank you / shout outs

* The extension manager is heavily inspired by the manager in [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Credits

Thanks to 

@TheSafdarAwan for PR #22

@costowell for PR #32
