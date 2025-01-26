# flygrep.nvim

> searching text in neovim floating window asynchronously 

![Image](https://github.com/user-attachments/assets/862a47a6-4620-4f3b-a1a1-df47c8e92ddc)

<!-- vim-markdown-toc GFM -->

- [Intro](#intro)
- [Requirements](#requirements)
- [Install](#install)
- [Command](#command)
- [Options](#options)
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

## Options

- `vim.g.flygrep_timer`: default is 200

## Key Bindings

| Key bindings | descretion                         |
| ------------ | ---------------------------------- |
| `<Enter>`    | open cursor item                   |
| `<Tab>`      | next item                          |
| `<S-Tab>`    | previous item                      |
| `<C-s>`      | open item in split window          |
| `<C-v>`      | open item in vertical split window |
| `<C-t>`      | open item in new tabpage           |
