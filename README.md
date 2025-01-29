# flygrep.nvim

> searching text in neovim floating window asynchronously 

![Image](https://github.com/user-attachments/assets/88e47b60-40f4-4e62-afbd-650562f302c8)

<!-- vim-markdown-toc GFM -->

- [Intro](#intro)
- [Requirements](#requirements)
- [Install](#install)
- [Command](#command)
- [Configuration](#configuration)
- [Key Bindings](#key-bindings)

<!-- vim-markdown-toc -->

## Intro

`flygrep.nvim` is a neovim plugin that can be used to search code asynchronously in real time. 


## Requirements

- [neovim](https://github.com/neovim/neovim): >= v0.10.0
- [ripgrep](https://github.com/BurntSushi/ripgrep)

## Install

- use [vim-plug](https://github.com/junegunn/vim-plug) package manager

```
Plug 'wsdjeg/flygrep.nvim'
```

## Command

- `:FlyGrep`: open flygrep in current directory

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
})
```

## Key Bindings

| Key bindings | descretion                         |
| ------------ | ---------------------------------- |
| `<Enter>`    | open cursor item                   |
| `<Tab>`      | next item                          |
| `<S-Tab>`    | previous item                      |
| `<C-s>`      | open item in split window          |
| `<C-v>`      | open item in vertical split window |
| `<C-t>`      | open item in new tabpage           |
