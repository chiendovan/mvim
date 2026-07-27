local M = {}

local ns_guides = vim.api.nvim_create_namespace('indent_guide_guides')
local ns_scope  = vim.api.nvim_create_namespace('indent_guide_scope')

local state = {
  timer         = vim.loop.new_timer(),
  event_id      = 0,
  current_scope = {},
  draw_status   = 'none',
}

M.config = {
  char             = '│',
  scope_char       = '│',
  debounce_ms      = 50,
  animation_ms     = 50,
  exclude_filetypes = {
    'neo-tree', 'NvimTree', 'TelescopePrompt', 'mason', 'lazy',
    'help', 'dashboard', 'alpha', 'starter',
  },
}

local function is_excluded(bufnr)
  local ft = vim.bo[bufnr].filetype
  for _, v in ipairs(M.config.exclude_filetypes) do
    if ft == v then return true end
  end
  return false
end

-- ── Highlights ──────────────────────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'IndentGuide',      { default = true, link = 'Whitespace' })
  vim.api.nvim_set_hl(0, 'IndentGuideScope', { default = true, link = 'Function' })
end

-- ── Indent helpers ──────────────────────────────────────────────────────────

local function get_line_indent(lnum)
  local prev = vim.fn.prevnonblank(lnum)
  if prev == 0 then return 0 end
  if prev == lnum then return vim.fn.indent(lnum) end
  -- blank line: use min of surrounding non-blank indents
  local next = vim.fn.nextnonblank(lnum)
  local next_indent = next == 0 and 0 or vim.fn.indent(next)
  return math.min(vim.fn.indent(prev), next_indent)
end

-- ── Indent guides ───────────────────────────────────────────────────────────

local function render_guides(bufnr, win)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_guides, 0, -1)
  local wininfo = vim.fn.getwininfo(win)[1]
  if not wininfo then return end
  local top = wininfo.topline
  local bot = wininfo.botline
  local sw  = vim.fn.shiftwidth()
  if sw == 0 then sw = vim.bo[bufnr].tabstop end

  for lnum = top, bot do
    local indent = get_line_indent(lnum)
    local levels = math.floor(indent / sw)
    for i = 1, levels do
      local col = (i - 1) * sw
      vim.api.nvim_buf_set_extmark(bufnr, ns_guides, lnum - 1, 0, {
        virt_text         = { { M.config.char, 'IndentGuide' } },
        virt_text_win_col = col,
        virt_text_pos     = 'overlay',
        hl_mode           = 'combine',
        priority          = 1,
      })
    end
  end
end

-- ── Scope detection ─────────────────────────────────────────────────────────

local function get_scope(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum   = cursor[1]
  local prev   = vim.fn.prevnonblank(lnum)
  if prev == 0 then return nil end
  local indent = vim.fn.indent(prev)
  local sw     = vim.fn.shiftwidth()
  if sw == 0 then sw = vim.bo[bufnr].tabstop end
  if indent < sw then return nil end

  local total = vim.fn.line('$')
  local top   = 1
  local bot   = total

  for l = lnum - 1, 1, -1 do
    if get_line_indent(l) < indent then
      top = l + 1
      break
    end
  end

  for l = lnum + 1, total do
    if get_line_indent(l) < indent then
      bot = l - 1
      break
    end
  end

  return {
    buf_id = bufnr,
    top    = top,
    bottom = bot,
    col    = indent - sw,
    indent = indent,
  }
end

-- ── Scope rendering ─────────────────────────────────────────────────────────

local function draw_scope_line(scope, lnum)
  if lnum < scope.top or lnum > scope.bottom then return false end
  vim.api.nvim_buf_set_extmark(scope.buf_id, ns_scope, lnum - 1, 0, {
    virt_text         = { { M.config.scope_char, 'IndentGuideScope' } },
    virt_text_win_col = scope.col,
    virt_text_pos     = 'overlay',
    hl_mode           = 'combine',
    priority          = 2,
  })
  return true
end

local function scope_equal(s1, s2)
  if type(s1) ~= 'table' or type(s2) ~= 'table' then return false end
  return s1.buf_id == s2.buf_id
    and s1.top    == s2.top
    and s1.bottom == s2.bottom
    and s1.col    == s2.col
end

local function scope_intersects(s1, s2)
  if type(s1) ~= 'table' or type(s2) ~= 'table' then return false end
  if s1.buf_id ~= s2.buf_id or s1.col ~= s2.col then return false end
  return (s2.top <= s1.top and s1.top <= s2.bottom)
      or (s1.top <= s2.top and s2.top <= s1.bottom)
end

local function animate_scope(scope, immediate)
  state.timer:stop()
  vim.api.nvim_buf_clear_namespace(scope.buf_id, ns_scope, 0, -1)

  local cursor  = vim.api.nvim_win_get_cursor(0)
  local origin  = math.min(math.max(cursor[1], scope.top), scope.bottom)
  local n_steps = math.max(origin - scope.top, scope.bottom - origin)
  local step    = 0
  local event_id = state.event_id

  local draw_step
  draw_step = vim.schedule_wrap(function()
    if state.event_id ~= event_id then return end

    draw_scope_line(scope, origin - step)
    if step > 0 then draw_scope_line(scope, origin + step) end

    if step >= n_steps then
      state.timer:stop()
      state.draw_status = 'finished'
      return
    end

    step = step + 1

    if immediate or M.config.animation_ms < 1 then
      draw_step()
    else
      state.timer:set_repeat(M.config.animation_ms)
      state.timer:again()
    end
  end)

  state.draw_status = 'drawing'
  -- start with a dummy large timeout so timer doesn't fire on its own initially
  state.timer:start(10000000, 0, draw_step)
  draw_step()
end

-- ── Event handlers ──────────────────────────────────────────────────────────

local function on_update()
  local bufnr = vim.api.nvim_get_current_buf()
  if is_excluded(bufnr) then return end
  local win   = vim.api.nvim_get_current_win()
  render_guides(bufnr, win)
end

local function on_cursor_moved()
  local bufnr = vim.api.nvim_get_current_buf()
  if is_excluded(bufnr) then return end
  state.event_id = state.event_id + 1
  local event_id = state.event_id

  vim.defer_fn(function()
    if state.event_id ~= event_id then return end
    local scope = get_scope(bufnr)
    if scope_equal(scope, state.current_scope) then return end
    local immediate = scope_intersects(scope, state.current_scope)
    state.current_scope = scope or {}
    if scope then
      animate_scope(scope, immediate)
    else
      state.timer:stop()
      vim.api.nvim_buf_clear_namespace(bufnr, ns_scope, 0, -1)
      state.draw_status = 'none'
    end
  end, M.config.debounce_ms)
end

local function on_leave()
  state.timer:stop()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_scope, 0, -1)
  state.current_scope = {}
  state.draw_status = 'none'
end

-- ── Setup ────────────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  setup_highlights()

  local aug = vim.api.nvim_create_augroup('IndentGuide', { clear = true })

  vim.api.nvim_create_autocmd(
    { 'BufEnter', 'TextChanged', 'TextChangedI', 'WinScrolled' },
    { group = aug, callback = on_update }
  )

  vim.api.nvim_create_autocmd(
    { 'CursorMoved', 'CursorMovedI' },
    { group = aug, callback = on_cursor_moved }
  )

  vim.api.nvim_create_autocmd(
    { 'BufLeave', 'WinLeave' },
    { group = aug, callback = on_leave }
  )
end

M.setup()

return M
