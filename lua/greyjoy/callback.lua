local utils = require("greyjoy.utils")
local greyjoy = require("greyjoy")

local greycall = {}

greycall.translate = function(obj)
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

greycall.extensions = function(arg, callback, callbackoptions)
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype
    local pluginname = arg or ""
    local fileobj = utils.new_file_obj(greyjoy.patterns, bufname, filetype)
    local rootdir = fileobj.rootdir
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
                callback(output, callbackoptions)
            else
                if rootdir then
                    for _, file in pairs(plugin_obj.files) do
                        if utils.file_exists(rootdir .. "/" .. file) then
                            local fileinfo = {
                                filename = file,
                                filepath = rootdir,
                            }
                            output = plugin_obj.parse(fileinfo)
                            callback(output, callbackoptions)
                        end
                    end
                end
            end
        end
    end
end

return greycall
