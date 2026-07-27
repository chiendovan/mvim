# myvim

Neovim config cá nhân.

## Cấu trúc

```
~/.config/myvim/
├── init.lua          # Entry point — tự động load toàn bộ file trong lua/
├── lua/
│   ├── base.lua      # Editor settings (encoding, indent, search, clipboard…)
│   ├── plugins.lua   # Quản lý plugin (packer.nvim)
│   ├── nerdtree.lua  # File explorer keymap
│   └── theme.lua     # Colorscheme
└── plugin/
    └── theme.lua
```

## Plugin

Quản lý bằng [packer.nvim](https://github.com/wbthomason/packer.nvim).

| Plugin | Mục đích |
|--------|----------|
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme |

## Cài đặt

```bash
git clone <repo-url> ~/.config/myvim
```

Mở Neovim và chạy:

```
:PackerSync
```

## Keymaps

| Phím | Chức năng |
|------|-----------|
| `<Space>e` | Toggle file explorer |

## Yêu cầu

- Neovim >= 0.8
- [packer.nvim](https://github.com/wbthomason/packer.nvim) đã được cài
- Font hỗ trợ icon (Nerd Font) để hiển thị devicons
