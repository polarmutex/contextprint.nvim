_contextprint_name_defaults = nil
_contextprint_config = nil
require("plenary.reload").reload_module("contextprint")
local context_print = require("contextprint")

function test()
    pcall(function()
        for idx = 1, 10 do
            print("test")
        end

        local idx = 1

        repeat
            if idx == 10 then
                print("test")
            end
            idx = idx + 1
        until idx > 10

        idx = 1

        while idx <= 10 do
            if idx == 10 then
                print("test")
            end
            idx = idx + 1
        end
    end)
end

print("Create Statement", context_print.create_statement())

