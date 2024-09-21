local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
    vim.notify(
        "This plugin requires telescope and plenary (https://github.com/nvim-telescope/telescope.nvim)",
        vim.log.levels.ERROR,
        { title = "Plugin error" }
    )
    return
end

local greytelescope = {}

local last_choice = ""

local greyjoy = require("greyjoy")
local utils = require("greyjoy.utils")
local async = require("plenary.async")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

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

local collect_output = function(output, on_item_collected)
    if type(output) == "table" then
        for _, x in pairs(output) do
            local newx = translate(x)
            on_item_collected({
                name = newx.name,
                value = newx,
            })
            async.util.sleep(1) -- TODO: find out why this improves performance (Or makes it more responsive)
        end
    end
end

greytelescope.run_async = function(
    arg,
    bufname,
    filetype,
    on_item_collected,
    on_complete
)
    local fileobj = utils.new_file_obj(greyjoy.patterns, bufname, filetype)
    local rootdir = fileobj.rootdir

    local pluginname = arg or ""

    async.run(function()
        -- TODO: do generically
        for p, v in pairs(greyjoy.extensions) do
            if
                pluginname == ""
                or pluginname == p
                or greyjoy.__in_group(pluginname, p)
            then
                if v.type == "global" then
                    local output = v.parse(fileobj)
                    collect_output(output, on_item_collected)

                    -- Do file based extensions
                elseif v.type == "file" then
                    if rootdir then
                        for _, file in pairs(v.files) do
                            if utils.file_exists(rootdir .. "/" .. file) then
                                local fileinfo = {
                                    filename = file,
                                    filepath = rootdir,
                                }
                                local output = v.parse(fileinfo)
                                collect_output(output, on_item_collected)
                            end
                        end
                    end
                end
            end
        end

        on_complete()
    end)
end

greytelescope.run = function(arg)
    if not has_telescope then
        vim.notify(
            "This function requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)",
            vim.log.levels.ERROR,
            { title = "Plugin error" }
        )
        return
    end

    local items = {}

    local get_selection_index = function()
        for index, data in pairs(items) do
            if data.name == last_choice then
                return index
            end
        end
        return #items
    end

    local generate_finder = function()
        return finders.new_table({
            results = items,
            entry_maker = function(entry)
                return {
                    value = entry,
                    ordinal = entry.name,
                    display = entry.name,
                }
            end,
        })
    end

    -- Get name of buffer before opening telescope, else we get the telescope buffer
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype

    local picker = pickers.new({}, {
        prompt_title = "Runners",
        finder = generate_finder(),
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(_, map)
            map("i", greyjoy.ui.telescope.keys.select, function(prompt_bufnr)
                local selection = action_state.get_selected_entry()

                last_choice = selection.value.value.name

                actions.close(prompt_bufnr)
                greyjoy.execute(selection.value.value)
            end)
            map("i", greyjoy.ui.telescope.keys.edit, function(prompt_bufnr)
                local current_picker =
                    action_state.get_current_picker(prompt_bufnr)
                local selection = current_picker:get_selection()

                local obj = selection.value.value
                local commandinput = table.concat(obj.command, " ")

                vim.ui.input({
                    prompt = "Edit before running: ",
                    default = obj.name,
                }, function(newname)
                    if newname then
                        if obj.orig_command then
                            local tmp = table.concat(obj.orig_command, " ")
                            greyjoy.overrides[tmp] = newname
                        else
                            greyjoy.overrides[commandinput] = newname
                        end

                        obj.command = utils.str_to_array(newname)
                        last_choice = newname

                        actions.close(prompt_bufnr)
                        greyjoy.execute(obj)
                    end
                end)
            end)
            return true
        end,
    })

    picker:find()

    -- On every new item we insert and refresh picker
    local function on_item_collected(item)
        table.insert(items, item)

        vim.schedule(function()
            picker:refresh(finders.new_table({
                results = items,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry.name,
                        ordinal = entry.name,
                    }
                end,
            }))
        end)
    end

    -- Once all plugins are done we need to set selection
    local function on_complete()
        local index = get_selection_index()
        picker:set_selection(picker:get_index(index))
        vim.schedule(function()
            print("All plugins processed!")
        end)
    end

    -- Start the asynchronous collection and processing
    greytelescope.run_async(
        arg,
        bufname,
        filetype,
        on_item_collected,
        on_complete
    )
end

return greytelescope
