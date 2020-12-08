local Utils = require("contextprint.utils")
local Nodes = require("contextprint.nodes")
local parsers = require("nvim-treesitter.parsers")

local M = {}

function get_name_defaults()
    return {
        ["function"] = "(anonymous)",
        ["if"] = "if",
        ["elif"] = "elif",
        ["else"] = "else",
        ["for"] = "for",
        ["for_in"] = "for_in",
        ["repeat"] = "repeat",
        ["while"] = "while",
        ["do"] = "do",
    }
end

-- TODO: If vs elseif seems to be odd
function clean_cache()
    local name_defaults = get_name_defaults()
    return {
        separator = "#",
        lua = {
            query = [[
(function (function_name) @function.name) @function.declaration
(function_definition) @function.declaration
(for_statement) @for.declaration
(for_in_statement) @for_in.declaration
(repeat_statement) @repeat.declaration
(while_statement) @while.declaration
(if_statement) @if.declaration
                ]],
                log = function(contents) return "print(\"" .. contents .. "\")" end,
                type_defaults = vim.tbl_extend("force", {}, name_defaults),
            },

            typescript = {
                -- I am missing const a = () => { ... };  In a sense, I should be able
                -- to get the name, but I don't know how to do reverse lookup via query
                -- if there is a name provided
                query = [[
(function_declaration (identifier) @function.name) @function.declaration
(class_declaration (type_identifier) @class.name) @class.declaration
(method_definition (property_identifier) @method.name) @method.declaration
(arrow_function) @function.declaration
(if_statement) @if.declaration
(for_statement) @for.declaration
(for_in_statement) @for_in.declaration
(do_statement) @do.declaration
(while_statement) @while.declaration
                ]],
                log = function(contents) return "console.error(\"" .. contents .. "\");" end,
                type_defaults = vim.tbl_extend("force", {}, name_defaults),
            },

            python = {
                query = [[
(function_definition (identifier) @function.name) @function.declaration
(class_definition (identifier) @class.name) @class.declaration
(if_statement) @if.declaration
(elif_clause) @elif.declaration
(else_clause) @else.declaration
(for_statement) @for.declaration
(while_statement) @while.declaration
                ]],
                log = function(contents) return "print(\"" .. contents .. "\");" end,
                type_defaults = vim.tbl_extend("force", {}, name_defaults),
            },
        }
end

M.reset_cache = function()
    _contextprint_config = clean_cache()
end

-- TODO: Runtime type filter
_contextprint_config = _contextprint_config or clean_cache()

local function first_non_null(...)
    local n = select('#', ...)
    for i = 1, n do
        local value = select(i, ...)

        if value ~= nil then
            return value
        end
    end
end

function merge(t1, t2)
    for key, value in pairs(t2) do --actualcode
        if type(value) == type({}) then
            if t1[key] == nil then
                t1[key] = value
            else
                merge(t1[key], value)
            end
        else
            t1[key] = value
        end
    end
end

-- config[lang] = {
    -- query = string
-- }
M.setup = function(opts)
    merge(_contextprint_config, opts or {})
end

M.create_statement = function()

    local ft = vim.api.nvim_buf_get_option(bufnr, 'ft')

    -- Check to see if tree-sitter is setup
    local lang = _contextprint_config[ft]
    if not lang then
        print("contextprint doesn't support this filetype", ft)
        return nil
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    -- TODO: Uses 0 for current buffer.  Should we fix this?
    local nodes = Nodes.get_nodes(lang.query, ft, _contextprint_config[ft].type_defaults or {})

    if nodes == nil then
        print("Unable to find any nodes.  Is your query correct?")
        return nil
    end

    nodes = Nodes.sort_nodes(Nodes.intersect_nodes(nodes, row, col))

    local path = ""
    local first = true
    local sep = (_contextprint_config[ft].separator or _contextprint_config.separator)
    for idx = 1, #nodes do
        if first then
            path = nodes[idx].name
            first = false
        else
            path = path .. sep .. nodes[idx].name
        end
    end

    return lang.log(path), row, col
end

M.add_statement = function(below)
    below = below or false

    local ft = vim.api.nvim_buf_get_option(bufnr, 'ft')

    -- Check to see if tree-sitter is setup
    if not parsers.has_parser() then
        print("tree sitter is not enabled for filetype", ft)
        return nil
    end

    local print_statement, row, col = M.create_statement()

    if print_statement == nil then
        print("Unable to find anything with your query.  Are you sure it is correct?")
        return
    end

    print("print_statement", print_statement, row, col)

    if below then
        vim.api.nvim_buf_set_lines(0, row, row, false, {print_statement})
        vim.api.nvim_feedkeys('j', 'n', false)
        vim.api.nvim_feedkeys('=', 'n', false)
        vim.api.nvim_feedkeys('=', 'n', false)
        vim.api.nvim_feedkeys('$', 'n', false)
    else
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {print_statement})
        vim.api.nvim_feedkeys('k', 'n', false)
        vim.api.nvim_feedkeys('=', 'n', false)
        vim.api.nvim_feedkeys('=', 'n', false)
        vim.api.nvim_feedkeys('$', 'n', false)
    end

end

return M
