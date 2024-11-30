local greyfzf = {}

local utils = require("greyjoy.utils")
local greyjoy = require("greyjoy")

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

local fzfadddata = function(co, fzf_cb, content, count, output)
    for _, result in ipairs(output) do
        local translated = translate(result)
        table.insert(content, translated)
        count = count + 1

        local key = count .. ":" .. translated.name
        content[key] = translated

        vim.schedule(function()
            fzf_cb(key, function()
                coroutine.resume(co)
            end)
        end)
        coroutine.yield()
    end
end

greyfzf.run = function(arg)
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype
    local pluginname = arg or ""
    local fileobj = utils.new_file_obj(greyjoy.patterns, bufname, filetype)
    local rootdir = fileobj.rootdir

    local fzf = require("fzf-lua")
    local content = {}
    local count = 0

    fzf.fzf_exec(function(fzf_cb)
        coroutine.wrap(function()
            local co = coroutine.running()

            for plugin, obj in pairs(greyjoy.extensions) do
                local plugin_obj = obj
                local plugin_type = plugin_obj.type

                if
                    pluginname == ""
                    or pluginname == plugin
                    or greyjoy.__in_group(pluginname, plugin)
                then
                    local output = {}
                    if plugin_type == "global" then
                        output = plugin_obj.parse(fileobj)
                        fzfadddata(co, fzf_cb, content, count, output)
                    else
                        if rootdir then
                            for _, file in pairs(plugin_obj.files) do
                                if
                                    utils.file_exists(rootdir .. "/" .. file)
                                then
                                    local fileinfo = {
                                        filename = file,
                                        filepath = rootdir,
                                    }
                                    output = plugin_obj.parse(fileinfo)
                                    fzfadddata(
                                        co,
                                        fzf_cb,
                                        content,
                                        count,
                                        output
                                    )
                                end
                            end
                        end
                    end
                end
            end
            fzf_cb()
        end)()
    end, {
        prompt = "Run> ",
        actions = {
            [greyjoy.ui.fzf.keys.select] = {
                fn = function(selected)
                    local cmd = content[selected[1]]
                    greyjoy.execute(cmd)
                end,
                silent = true,
            },
            [greyjoy.ui.fzf.keys.edit] = {
                fn = function(selected)
                    local command = content[selected[1]]

                    local commandinput = table.concat(command.command, " ")

                    vim.ui.input(
                        { prompt = "Edit", default = commandinput },
                        function(input)
                            if input then
                                if command.orig_command then
                                    local tmp =
                                        table.concat(command.orig_command, " ")
                                    greyjoy.overrides[tmp] = input
                                else
                                    greyjoy.overrides[commandinput] = input
                                end

                                command.command = utils.str_to_array(input)
                                greyjoy.execute(command)
                            end
                        end
                    )
                end,
                silent = true,
            },
        },
    })
end

return greyfzf
