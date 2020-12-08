# contextprintf.nvim
neovim plugin to add context aware print debug statements

 - Uses tree-sitter to find context of your current cursor and create
a print statement in the current language that prints that context

# Installation

* I only tested on Neovim 0.5

Use your favorite plugin manager to install
```
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'bryall/contextprint.nvim'
```

# Supported Languages / Planned

- [x] Lua
- [ ] Python
- [x] Typescript
- [ ] C/C++

# Options

Call the below statment to change the defaults

```
    require('contextprint').setup({
        separator_char = "#",
        <filetype> = {
            separator = "#",
            query = [[ <language specific queries> ]],
            log = function(contents) to return print statement to insert
            type_defaults = vim.tbl_extend to change name defaults
        }
    })
```

# to add context print statement

```
    require('contextprint').add_statement()
```

# Language Details

contextprint provides the following context for the supplied languages

## Lua

- [x] function
- [x] function_definition
- [x] for_statement
- [x] for_in_statement
- [x] repeat_statement
- [x] while_statement
- [x] if_statement

## Typescript

- [x] function_declaration
- [x] class_declaration
- [x] method_definition
- [x] arrow_function
- [x] if_statement
- [x] for_statement
- [x] for_in_statement
- [x] do_statement
- [x] while_statement

