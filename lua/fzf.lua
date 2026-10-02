local M = {}

function M.init()
  require("fzf-lua").setup({
    winopts = {
      height = 0.85,
      width = 0.80,
    },
    files = { multiprocess = false },
    grep = { multiprocess = false, query_delay = 150 },
    oldfiles = { multiprocess = false },
  })
end

function M.files()
  require("fzf-lua").files()
end

function M.grep()
  require("fzf-lua").live_grep()
end

function M.buffers()
  require("fzf-lua").buffers()
end

function M.help()
  require("fzf-lua").help_tags()
end

function M.oldfiles()
  require("fzf-lua").oldfiles()
end

vim.keymap.set("n", "<Space>ff", M.files, { silent = true })
vim.keymap.set("n", "<Space>fg", M.grep, { silent = true })
vim.keymap.set("n", "<Space>fb", M.buffers, { silent = true })
vim.keymap.set("n", "<Space>fh", M.help, { silent = true })
vim.keymap.set("n", "<Space>fr", M.oldfiles, { silent = true })

M.init()

return M
