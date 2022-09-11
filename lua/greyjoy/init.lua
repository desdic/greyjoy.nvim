local greyjoy = {}
local config = require("greyjoy.config")
local utils = require("greyjoy.utils")
local findroot = require("greyjoy.findroot")
local _extensions = require("greyjoy._extensions")

-- Override defaults with configuration
greyjoy.setup = function(options)
    setmetatable(greyjoy, {__newindex = config.set, __index = config.get})

    if options ~= nil then
        for k, v in pairs(options) do config.defaults[k] = v end
    end

    _extensions.set_config(config.defaults["extensions"] or {})
end

function greyjoy.load_extension(name) return _extensions.load(name) end

function greyjoy.register_extension(mod) return _extensions.register(mod) end

greyjoy.extensions = require("greyjoy._extensions").manager

greyjoy.run = function(_)
    -- just return if disabled
    if not greyjoy.enable then return end

    local filetype = vim.bo.filetype
    local fullname = vim.api.nvim_buf_get_name(0)
    local filename = utils.basename(fullname)
    local filepath = utils.dirname(fullname)

	local fileobj = {filetype=filetype, fullname=fullname, filename=filename, filepath=filepath}

    local elements = {}

    local rootdir = findroot.find(greyjoy.patterns, filepath)

    for _, v in pairs(greyjoy.extensions) do
        -- Do global based
        if v.type == "global" then
            local output = v.parse(fileobj)
            if output then
                for _, elem in pairs(output) do
                    if greyjoy.show_command then
                        elem["name"] = elem["name"] .. " (" ..
                                           table.concat(elem["command"], " ") ..
                                           ")"
                    end

                    table.insert(elements, elem)
                end
            end
        end

        -- Do file based extensions
        if v.type == "file" then
            if rootdir then
                for _, file in pairs(v.files) do
                    if utils.file_exists(rootdir .. "/" .. file) then

						local fileinfo = {filename=file, filepath=rootdir}
                        local output = v.parse(fileinfo)
                        if output then
                            for _, elem in pairs(output) do
                                if greyjoy.show_command then
                                    elem["name"] =
                                        elem["name"] .. " (" ..
                                            table.concat(elem["command"], " ") ..
                                            ")"
                                end

                                table.insert(elements, elem)
                            end
                        end
                    end
                end
            end
        end
    end

    utils.menu(elements, greyjoy.show_command_in_output, {border=greyjoy.border, style=greyjoy.style})
end

vim.api.nvim_create_user_command("Launch", function(args) greyjoy.run(args) end,
                                 {nargs = "*", desc = "Run greyjoy"})

return greyjoy
