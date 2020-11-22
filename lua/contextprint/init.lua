
local treesitter = vim.treesitter
local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local M = {}

_config = _config or {}

local function first_non_null(...)
  local n = select('#', ...)
  for i = 1, n do
    local value = select(i, ...)

    if value ~= nil then
      return value
    end
  end
end

M.config = _config

M.setup = function(opts)
    opts = opts or {}

    local function get(name, default_val)
        return first_non_null(opts[name], M.config[name], default_val)
    end

    local function set(name, default_val)
        M.config[name] = get(name, default_val)
    end

    set("separator_char", ":")
    set("include_class", true)
    set("include_function", true)
    set("include_method", true)
    set("include_if", false)
    set("include_for", false)

end


local look_for_name = function(node)

    local cur_node_text = nil

    -- Check to see if we have named node "name"
    if next(node:field("name")) ~= nil then
        cur_node_text = ts_utils.get_node_text(node:field("name")[1])[1]
        -- Loop over child nodes looking for "name" in node type
    else
        for child in node:iter_children() do
            if child:type():find("name") then
                cur_node_text = ts_utils.get_node_text(child)[1]
                break
            end
        end
    end

    if cur_node_text ~= nil then
        return cur_node_text
    else
        return nil
    end
end

M.add_statement = function()
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

    while current_node do

        local cur_node_type = current_node:type()
        local context_text = nil

        -- Check to see if we should include this node
        if _config.include_class then
            if cur_node_type:find("class") ~= nil then
                context_text = look_for_name(current_node)
            end
        end
        if _config.include_function then
            if cur_node_type:find("function") ~= nil then
                context_text = look_for_name(current_node)
            end
        end
        if _config.include_method then
            if cur_node_type:find("method") ~= nil then
                context_text = look_for_name(current_node)
            end
        end
        if _config.include_if then
            if cur_node_type:find("if") ~= nil then
                context_text = "if"
            end
        end
        if _config.include_for then
            if cur_node_type:find("for") ~= nil then
                context_text = "for"
            end
        end

        if context_text ~= nil then
            if context == nil then
                context = context_text
            else
                context = context_text .. _config.separator_char .. context
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
