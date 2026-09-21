local M = {}

local function label(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":t")
end

local function list_buffers()
  local bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      bufs[#bufs + 1] = bufnr
    end
  end
  return bufs
end

function M.render()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}

  for i, bufnr in ipairs(list_buffers()) do
    parts[#parts + 1] = bufnr == cur and "%#TabLineSel#" or "%#TabLine#"
    parts[#parts + 1] = " " .. i .. " " .. label(bufnr) .. " "
  end

  parts[#parts + 1] = "%#TabLineFill#"
  return table.concat(parts)
end

function M.switch_at(index)
  local bufnr = list_buffers()[index]
  if bufnr then
    vim.api.nvim_set_current_buf(bufnr)
  end
end

function M.init()
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'bufferline'.render()"

  local aug = vim.api.nvim_create_augroup("MvimBufferline", { clear = true })
  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufWipeout" }, {
    group = aug,
    callback = function()
      vim.cmd("redrawtabline")
    end,
  })

  for i = 1, 4 do
    vim.keymap.set("n", "<Space>" .. i, function()
      M.switch_at(i)
    end, { silent = true })
  end
end

M.init()

return M
