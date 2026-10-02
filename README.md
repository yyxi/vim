# Neovim configuration

## Install

On Linux or macOS, install these tools and make sure they are on your `PATH`:

- Neovim 0.12.x and Git 2.52+.
- CPython 3.12–3.14 (non-free-threaded), uv, Node.js 24+, and pnpm 11.x (11.5.2+).
- Tree-sitter CLI 0.26.1+, a C/C++ compiler, and Make.

Cargo 1.85+ is optional.

If `~/.config/nvim` contains another configuration, back it up and move it first.
The first installation needs an internet connection:

```sh
git clone --depth 1 https://github.com/yyxi/vim.git ~/.vim
~/.vim/manage install
nvim
```

The installer downloads and builds dependencies, then links `~/.config/nvim` to
`~/.vim`.

To reuse an existing installation without downloading dependencies, run
`~/.vim/manage install --offline`.

## Keybindings

| Keybinding       | Description                             |
| ---------------- | --------------------------------------- |
| `<C-Down>`       | Next Diagnostic                         |
| `<C-Up>`         | Previous Diagnostic                     |
| `<Down>`         | Go to next search match                 |
| `<Left>`         | Previous Buffer                         |
| `<Right>`        | Next Buffer                             |
| `<Up>`           | Go to previous search match             |
| `<c-s>`          | Flash Search (command mode)             |
| `<space><space>` | Switch Buffer                           |
| `<space>?`       | Which-Key popup                         |
| `<space>A`       | Code Action                             |
| `<space>C`       | Block comment                           |
| `<space>D`       | Documentation comment                   |
| `<space>F`       | Fix                                     |
| `<space>Q`       | Quit Neovim                             |
| `<space>R`       | References                              |
| `<space>S`       | Document Symbols                        |
| `<space>S`       | Sort (visual mode)                      |
| `<space>W`       | Workspace Symbols                       |
| `<space>a`       | Align                                   |
| `<space>b`       | Buffers                                 |
| `<space>cA`      | Add comment at end of line              |
| `<space>cC`      | Block comment toggle                    |
| `<space>cO`      | Add comment above                       |
| `<space>c`       | Comment                                 |
| `<space>cc`      | Line comment toggle                     |
| `<space>co`      | Add comment below                       |
| `<space>d`       | Definitions                             |
| `<space>e`       | Find Files                              |
| `<space>f`       | Format                                  |
| `<space>g`       | Live Grep                               |
| `<space>i`       | Implementations                         |
| `<space>j`       | Join Toggle                             |
| `<space>n`       | case conversion                         |
| `<space>q`       | Delete buffer                           |
| `<space>r`       | Rename symbol                           |
| `<space>sF`      | Find surrounding (left)                 |
| `<space>sa`      | Add surrounding                         |
| `<space>sd`      | Delete surrounding                      |
| `<space>sf`      | Find surrounding (right)                |
| `<space>sr`      | Replace surrounding                     |
| `<space>t`       | Type Definitions                        |
| `<space>y`       | Yank History                            |
| `<space>z`       | Zen Mode                                |
| `N`              | Previous search match (direction aware) |
| `gf`             | Go to file                              |
| `n`              | Next search match (direction aware)     |
| `vv`             | Flash Treesitter                        |
