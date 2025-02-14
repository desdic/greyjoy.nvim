local greyfzf = {}

local utils = require("greyjoy.utils")
local greyjoy = require("greyjoy")
local callback = require("greyjoy.callback")

local fzfcallback = function(output, callbackoptions)
    for _, result in ipairs(output) do
        local translated = callback.translate(result)
        table.insert(callbackoptions.content, translated)
        callbackoptions.count = callbackoptions.count + 1

        local key = callbackoptions.count .. ":" .. translated.name
        callbackoptions.content[key] = translated

        vim.schedule(function()
            callbackoptions.fzf_cb(key, function()
                coroutine.resume(callbackoptions.co)
            end)
        end)
        coroutine.yield()
    end
end

greyfzf.run = function(arg)
    local fzf = require("fzf-lua")
    local content = {}
    local count = 0

    -- bufname and filetype must be before fzf otherwise data shows the fzf buffer
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype

    fzf.fzf_exec(function(fzf_cb)
        coroutine.wrap(function()
            local co = coroutine.running()

            callback.extensions(arg, fzfcallback, {
                co = co,
                fzf_cb = fzf_cb,
                content = content,
                count = count,
            }, bufname, filetype)

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
