local M = {}

function M.line_empty(line_idx)
  local line = vim.api.nvim_buf_get_lines(0, line_idx, line_idx + 1, false)[1]
  return line == nil or #line == 0
end

function M.is_empty(str)
  return str == nil or #str == 0
end

return M
