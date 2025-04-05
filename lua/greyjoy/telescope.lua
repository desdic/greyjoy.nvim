local greytelescope = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

local utils = require("greyjoy.utils")
local greyjoy = require("greyjoy")
local callback = require("greyjoy.callback")

local all_results = {}
local opts = {}

local generate_new_finder = function()
    return finders.new_table({
        results = all_results,
        entry_maker = function(entry)
            return {
                name = entry.name,
                value = entry.name,
                display = entry.name,
                ordinal = entry.name,
                command = entry.command,
                orig_command = entry.orig_command or nil,
                pre_hook = entry.pre_hook or nil,
                post_hook = entry.post_hook or nil,
                path = entry.path,
            }
        end,
    })
end

local translate = function(obj)
    local orig_command = nil
    local commandinput = table.concat(obj.command, " ")
    if greyjoy.overrides[commandinput] then
        orig_command = obj.command
        obj.command = utils.str_to_array(greyjoy.overrides[commandinput])
        obj.name = greyjoy.overrides[commandinput]
    end
    obj.orig_command = orig_command
    return obj
end

greytelescope.run = function(arg)
    all_results = {}

    local picker = pickers.new(opts, {
        prompt_title = "Runners",
        finder = generate_new_finder(),
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(_, map)
            map(
                "i",
                greyjoy.ui.telescope.keys.select,
                function(cur_prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    actions.close(cur_prompt_bufnr)

                    greyjoy.execute(selection)
                end
            )

            map("i", greyjoy.ui.telescope.keys.edit, function(cur_prompt_bufnr)
                local current_picker =
                    action_state.get_current_picker(cur_prompt_bufnr)
                local selection = current_picker:get_selection()

                local obj = selection
                local commandinput = table.concat(obj.command, " ")

                vim.ui.input({
                    prompt = "Edit command before running: ",
                    default = commandinput,
                }, function(newname)
                    if newname then
                        if obj.orig_command then
                            local tmp = table.concat(obj.orig_command, " ")
                            greyjoy.overrides[tmp] = newname
                        else
                            greyjoy.overrides[commandinput] = newname
                        end

                        obj.command = utils.str_to_array(newname)

                        actions.close(cur_prompt_bufnr)
                        greyjoy.execute(obj)
                    end
                end)
            end)

            return true
        end,
    })

    local function handle_new_results(new_results)
        if type(new_results) == "table" then
            for _, result in ipairs(new_results) do
                local newresult = translate(result)
                result.name = newresult.name

                table.insert(all_results, newresult)
            end
        end

        picker:refresh(generate_new_finder(), opts)
    end

    local function telescopecallback(output)
        vim.schedule(function()
            handle_new_results(output)
        end)
    end

    callback.extensions(arg, telescopecallback, {})

    picker:find()
end

return greytelescope
