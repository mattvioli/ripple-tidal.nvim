local config = require("tidal.config")

local M = {}

local ns = config.namespace
local hl_opts = config.options.selection_highlight
local higroup = "TidalRippleSent"

vim.api.nvim_set_hl(0, higroup, hl_opts.highlight)

function M.apply_highlight(start, finish)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.hl.range(bufnr, ns, higroup, start, finish, {
    regtype = "v",
    inclusive = true,
    priority = vim.hl.priorities.user,
    timeout = hl_opts.timeout,
  })
end

function M.clear_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

return M
