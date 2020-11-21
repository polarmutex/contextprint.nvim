
local treesitter = vim.treesitter
local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local M = {}

function M.add_statement()
    -- Check to see if tree-sitter is setup
    if not parsers.has_parser() then
        return nil
    end

    -- find current tree-sitter node at the current cursor
    local current_node = ts_utils.get_node_at_cursor()
    if not current_node then
        return nil
    end

    local context = nil

    -- try local queries

    local starting_node = current_node

    while current_node do

        local is_class = current_node:type():find("class") ~= nil
        local is_function = current_node:type():find("function") ~= nil
        local is_method = current_node:type():find("method") ~= nil

        if is_class or is_function or is_method then

            local cur_node_text = nil

            -- Check to see if we have named node "name"
            if next(current_node:field("name")) ~= nil then
                cur_node_text = ts_utils.get_node_text(current_node:field("name")[1])[1]
            -- Loop over child nodes looking for "name" in node type
            else
                for child in current_node:iter_children() do
                    if child:type():find("name") then
                        cur_node_text = ts_utils.get_node_text(child)[1]
                        break
                    end
                end
            end

            if context == nil then
                context = cur_node_text
            else
                context = cur_node_text .. ':' .. context
            end
        end
        -- goto next parent
        current_node = current_node:parent()
    end

    if context == nil then
        print("Could not find context")
        return
    end

    buf_filetype = vim.bo.filetype
    if buf_filetype == "lua" then
        context = "print(\"" .. context .. "\")"
    elseif  buf_filetype == "python" then
        context = "print(\"" .. context .. "\")"
    elseif buf_filetype:find("typescript") then
        context = "console.log(\"" .. context .. "\")"
    else
        print("Unsupported filetype: " .. buf_filetype)
        return
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, {context})
    vim.api.nvim_feedkeys('j', 'n', false)
    vim.api.nvim_feedkeys('=', 'n', false)
    vim.api.nvim_feedkeys('=', 'n', false)
    vim.api.nvim_feedkeys('k', 'n', false)

end

return M
