# myvim

Personal Neovim configuration.

## Structure

```
~/.config/myvim/
├── init.lua               # Entry point — auto-loads all files in lua/
├── lua/
│   ├── base.lua           # Editor settings (encoding, indent, search, clipboard…
│   ├── plugins.lua        # Plugin management (packer.nvim)
│   ├── nerdtree.lua       # File explorer keymap
│   ├── indent_guide.lua   # Custom indent guides & scope highlighting
│   └── theme.lua          # Colorscheme
└── plugin/
    └── theme.lua
```

## Plugins

Managed with [packer.nvim](https://github.com/wbthomason/packer.nvim).

| Plugin | Purpose |
|--------|---------|
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme |

## Installation

```bash
git clone <repo-url> ~/.config/myvim
```

Open Neovim and run:

```
:PackerSync
```

## Keymaps

| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file explorer |

## Requirements

- Neovim >= 0.8
- [packer.nvim](https://github.com/wbthomason/packer.nvim) installed
- A Nerd Font for icon rendering
