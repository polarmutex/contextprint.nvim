local ts_utils = require("nvim-treesitter.ts_utils")
local ts_query = require("nvim-treesitter.query")
local parsers = require("nvim-treesitter.parsers")
local locals = require("nvim-treesitter.locals")
local utils = require("contextprint.utils")

--[[
--Parsers
{
  available_parsers = <function 1>,
  ft_to_lang = <function 2>,
  get_buf_lang = <function 3>,
  get_parser = <function 4>,
  get_parser_configs = <function 5>,
  get_tree_root = <function 6>,
  has_parser = <function 7>,
  lang_match_ft = <function 8>,
  lang_to_ft = <function 9>,
  list: {...},
  maintained_parsers = <function 10>,
  reset_cache = <function 11>
}

--Utils
{
  get_named_children = <function 1>,
  get_next_node = <function 2>,
  get_node_at_cursor = <function 3>,
  get_node_range = <function 4>,
  get_node_text = <function 5>,
  get_previous_node = <function 6>,
  goto_node = <function 7>,
  highlight_node = <function 8>,
  highlight_range = <function 9>,
  is_in_node_range = <function 10>,
  is_parent = <function 11>,
  memoize_by_buf_tick = <function 12>,
  node_length = <function 13>,
  node_to_lsp_range = <function 14>,
  swap_nodes = <function 15>,
  update_selection = <function 16>
}

--
function get_function_name(node)
    for idx = 0, node:child_count() - 1 do
        local child = node:get
        if node:child(idx)
    end
    return nil
end
--]]
--
--
local M = {}

-- Array<node_wrapper>
M.intersect_nodes = function(nodes, row, col)
    local found = {}
    for idx = 1, #nodes do
        local node = nodes[idx]
        local sRow = node.dim.s.r
        local sCol = node.dim.s.c
        local eRow = node.dim.e.r
        local eCol = node.dim.e.c

        if utils.intersects(row, col, sRow, sCol, eRow, eCol) then
            table.insert(found, node)
        end
    end

    return found
end

M.count_parents = function(node)
    local count = 0
    local n = node.declaring_node
    while n ~= nil do
        n = n:parent()
        count = count + 1
    end
    return count
end

-- @param nodes Array<node_wrapper>
-- perf note.  I could memoize some values here...
M.sort_nodes = function(nodes)
    table.sort(nodes, function(a, b)
        return M.count_parents(a) < M.count_parents(b)
    end)
    return nodes
end

-- local lang = vim.api.nvim_buf_get_option(bufnr, 'ft')
-- node_wrapper
-- returns [{
--   declaring_node = tsnode
--   dim: {s: {r, c}, e: {r, c}},
--   name: string
--   type: string
-- }]
M.get_nodes = function(query, lang, defaults, bufnr)
    bufnr = bufnr or 0
    local success, parsed_query = pcall(function()
        return vim.treesitter.parse_query(lang, query)
    end)

    if not success then
        return nil
    end

    local parser = parsers.get_parser(bufnr, lang)
    local root = parser:parse()[1]:root()
    local start_row, _, end_row, _ = root:range()

    local results = {}
    for match in ts_query.iter_prepared_matches(parsed_query, root, bufnr, start_row, end_row) do
        local sRow, sCol, eRow, eCol
        local declaration_node
        local type = "no_type"
        local name = nil

        locals.recurse_local_nodes(match, function(_, node, path)
            local idx = string.find(path, ".", 1, true)
            local op = string.sub(path, idx + 1, #path)

            type = string.sub(path, 1, idx - 1)
            if name == nil then
                name = defaults[type] or "empty"
            end

            if op == "name" then
                name = ts_utils.get_node_text(node)[1]
            elseif op == "declaration" then
                declaration_node = node
                sRow, sCol, eRow, eCol = node:range()
                sRow = sRow + 1
                eRow = eRow + 1
                sCol = sCol + 1
                eCol = eCol + 1
            end
        end)

        if declaration_node ~= nil then
            table.insert(results, {
                declaring_node = declaration_node,
                dim = {
                    s = {r = sRow, c = sCol},
                    e = {r = eRow, c = eCol},
                },
                name = name,
                type = type,
            })
        end
    end

    return results
end

return M
--
-- local nodes = M.get_nodes(
-- [[
-- (function (function_name) @function.name) @function.declaration
-- (function_definition) @function.declaration
-- ]],
-- "lua"
-- )
