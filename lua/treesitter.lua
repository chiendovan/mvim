require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "lua", "vim", "vimdoc", "bash",
    "json", "yaml", "markdown", "markdown_inline",
    "javascript", "typescript", "python",
  },
  auto_install = true,
  highlight = {
    enable = true,
  },
})
