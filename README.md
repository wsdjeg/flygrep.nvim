# flygrep.nvim

> _flygrep.nvim_ is a plugin to search text in neovim floating window asynchronously

[![](https://spacevim.org/img/build-with-SpaceVim.svg)](https://spacevim.org)
[![GPLv3 License](https://img.spacevim.org/license-GPLv3-blue.svg)](LICENSE)

![flygrep.nvim](https://img.spacevim.org/flygrep.nvim.gif)

<!-- vim-markdown-toc GFM -->

* [Intro](#intro)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Key Bindings](#key-bindings)
* [Feedback](#feedback)

<!-- vim-markdown-toc -->

## Intro

`flygrep.nvim` is a neovim plugin that can be used to search code asynchronously in real time.

## Requirements

- [neovim](https://github.com/neovim/neovim): >= v0.10.0
- [ripgrep](https://github.com/BurntSushi/ripgrep): If you are using other searching tool, you need to set command option of flygrep.

## Installation

- use [nvim-plug](https://github.com/wsdjeg/nvim-plug)

```lua
require('plug').add({
    {
        'wsdjeg/flygrep.nvim',
        config = function()
            require('flygrep').setup()
        end,

        depends = { { 'wsdjeg/job.nvim' } },
    },
})
```

```
Plug 'wsdjeg/flygrep.nvim'
```

## Usage

- `:FlyGrep`: open flygrep in current directory
- `:lua require('flygrep').open(opt)`: opt supports following keys,
  - cwd: root directory of searching job
  - input: default input text in prompt window

search text in buffer directory:

```lua
require('flygrep').open({
  cwd = vim.fn.fnamemodify(vim.fn.bufname(), ':p:h'),
})
```

search text under the cursor:

```lua
require('flygrep').open({
  input = vim.fn.expand('<cword>')
})
```

## Configuration

```lua
require('flygrep').setup({
    color_templete = {
        a = {
            fg = '#2c323c',
            bg = '#98c379',
            ctermfg = 16,
            ctermbg = 114,
            bold = true,
        },
        b = {
            fg = '#abb2bf',
            bg = '#3b4048',
            ctermfg = 145,
            ctermbg = 16,
            bold = false,
        },
    },
    timeout = 200,
    command = {
        execute = 'rg',
        default_opts = {
            '--no-heading',
            '--color=never',
            '--with-filename',
            '--line-number',
            '--column',
            '-g',
            '!.git',
        },
        recursive_opt = {},
        expr_opt = { '-e' },
        fixed_string_opt = { '-F' },
        default_fopts = { '-N' },
        smart_case = { '-S' },
        ignore_case = { '-i' },
        hidden_opt = { '--hidden' },
    },
    matched_higroup = 'IncSearch',
    enable_preview = false,
    window = {
        width = 0.8,   -- flygrep screen width, default is vim.o.columns * 0.8
        height = 0.8,  -- flygrep screen height, default is vim.o.lines * 0.8
        col = 0.1,     -- flygrep screen start col, default is vim.o.columns * 0.1
        row = 0.1,     -- flygrep screen start row, default is vim.o.lines * 0.1
    },
})
```

## Key Bindings

| Key bindings         | descretion                         |
| -------------------- | ---------------------------------- |
| `<Enter>`            | open cursor item                   |
| `<Tab>` or `<C-j>`   | next item                          |
| `<S-Tab>` or `<C-k>` | previous item                      |
| `<C-s>`              | open item in split window          |
| `<C-v>`              | open item in vertical split window |
| `<C-t>`              | open item in new tabpage           |
| `<C-p>`              | toggle preview window              |
| `<C-h>`              | toggle display hidden files        |

## Feedback

If you encounter any bugs or have suggestions, please file an issue in the [issue tracker](https://github.com/wsdjeg/flygrep.nvim/issues)
