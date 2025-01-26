# flygrep.nvim

> searching text in neovim floating window asynchronously 

![Image](https://github.com/user-attachments/assets/0618e14b-ba1c-4bd0-b9d3-2bca62f3b92e)

<!-- vim-markdown-toc GFM -->

- [Intro](#intro)
- [Install](#install)
- [Command](#command)
- [Options](#options)
- [Key Bindings](#key-bindings)

<!-- vim-markdown-toc -->

## Intro

`flygrep.nvim` is a neovim plugin that can be used to search code asynchronously in real time.

## Install

**vim-plug:**

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
