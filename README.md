# contextprintf.nvim
neovim plugin to add context aware print debug statements

 - Uses tree-sitter to find context of your current cursor and create
a print statement in the current language that prints that context

 - currently is puts the print statement on the line below your cursor

 - currently only add the following context
    - [x] Classes
    - [x] Functions
    - [x] Methods

# Installation

* I only tested on Neovim 0.5

Use your favorite plugin manager to install
```
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'bryall/contextprint.nvim'
```

# Supported Languages

- [x] Lua
- [x] Python
- [x] Typescript
- [ ] C/C++

# Options

```
    require('contextprint').setup({
        separator_char = ":",
        include_class = true,
        include_function = true,
        include_method = true,
        include_if = false,
        include_for = false
    })
```

# to add context print statement

```
    require('contextprint').add_statement()
```
