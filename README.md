# flygrep.nvim

> grep on the fly in neovim

![Image](https://github.com/user-attachments/assets/0618e14b-ba1c-4bd0-b9d3-2bca62f3b92e)

<!-- vim-markdown-toc GFM -->

- [Command](#command)
- [Options](#options)
- [Key Bindings](#key-bindings)

<!-- vim-markdown-toc -->

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
