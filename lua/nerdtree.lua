local M = {}
local api = vim.api

M.init = function() end

function M.call()
  require("neo-tree.command").execute({ toggle = true })
end


vim.api.nvim_set_keymap("n", "<Space>e", [[:lua require'nerdtree'.call()<CR>]], { noremap = true, silent = true })

M.init()

return M
