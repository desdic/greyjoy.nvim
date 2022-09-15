# greyjoy.nvim

![Test](https://github.com/desdic/greyjoy.nvim/actions/workflows/ci.yml/badge.svg)

## What is greyjoy

`greyjoy.nvim` is a pluggable pattern/file based launcher.

![Demo of greyjoy](doc/greyjoy.gif?raw=true "Demo of greyjoy")

greyjoy uses vim.ui.select so the settings from (telescope, dressing etc.) menu will reflect it. The above example uses telescope.

Integration with [toggleterm](https://github.com/akinsho/toggleterm.nvim) is also provided.

## Requirements

Neovim 0.7+ is required

## Default settings

```
{
  enable = true,
  border = "rounded", -- style for vim.ui.selector
  style = "minimal",
  show_command = false, -- show command to run in menu
  show_command_in_output = true, -- show command that was just executed in output
  patterns = {".git", ".svn"}, -- patterns to find the root of the project
  output_result = "buffer", -- buffer or to toggleterm
  extensions = {}, -- no extensions are loaded per default
}
```

## Extensions

Default `greyjoy` does not have any extensions enabled.

### generic

`generic` extension is a global module that does not take into account if we are in a project (found via the patterns). Commands to run can be matched using `filetype`, `filename`, `filepath`

example:
```
generic = {
  commands = {
    ["run test.py"] = {
      command = {"./test.py"},
      filetype = "python",
      filename = "test.py"
    }
  }
},
```

The above example is only triggered if a file is of type `python` and the filename matches `test.py`

### makefile

The `makefile` extension is filebased and will only trigger if a `Makefile` is located in the project root. It finds all targets for a `Makefile`.

requires `make` and `awk` to work.

### vscode_tasks

The `vscode_tasks` extension is filebased and will only trigger if `.vscode/tasks.json` exists in the project root

### kitchen

The `kitchen` extension is also filebased and looks for `.kitchen.yml` and requires `kitchen` (from chefdk or cinc-workstation) + `awk` to be installed.

This extension has a few config options like which `kitchen` targets you want

Default is:

```
kitchen = {
  targets = {"converge", "verify", "test", "destroy"}, -- targets
  include_all = false, -- include all in list
}

```

## Installing

using packer

```
use({"desdic/greyjoy.nvim",
  config = function()
    local greyjoy = require("greyjoy")
    greyjoy.setup({
      output_results = "toggleterm",
      extensions = {
        generic = {
          commands = {
            ["run test.py"] = {
              command = {"./test.py"},
              filetype = "python"
            }
          }
        },
        kitchen = {
          targets = {"converge", "verify"},
          include_all = false,
        }
      }
    })
    greyjoy.load_extension("generic")
    greyjoy.load_extension("vscode_tasks")
    greyjoy.load_extension("makefile")
    greyjoy.load_extension("kitchen")
  end
})
```

Once installed and reloaded you can use `:Greyjoy` to run it.

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
