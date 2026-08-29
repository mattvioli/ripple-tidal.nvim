local config = require("tidal.config")

local M = {}

local markers = {}

function M.enqueue(bufnr, start_line, end_line, orbit)
  local ns = config.playhead_ns
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local line = math.min(start_line, line_count - 1)

  for _, m in ipairs(markers) do
    if m.bufnr == bufnr and m.line == line then
      return
    end
  end

  local id = vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    sign_text = "▶",
    sign_hl_group = "TidalRipplePlayhead",
    priority = vim.hl.priorities.user + 10,
    strict = false,
  })
  table.insert(markers, { id = id, bufnr = bufnr, line = line, orbit = orbit })
end

function M.clear(orbit)
  if orbit then
    for i = #markers, 1, -1 do
      local marker = markers[i]
      if marker.orbit == orbit then
        if vim.api.nvim_buf_is_valid(marker.bufnr) then
          pcall(vim.api.nvim_buf_del_extmark, marker.bufnr, config.playhead_ns, marker.id)
        end
        table.remove(markers, i)
      end
    end
    return
  end

  for _, marker in ipairs(markers) do
    if vim.api.nvim_buf_is_valid(marker.bufnr) then
      pcall(vim.api.nvim_buf_del_extmark, marker.bufnr, config.playhead_ns, marker.id)
    end
  end
  markers = {}
end

function M.on_cycle(parsed)
end

function M.reset()
  M.clear()
end

return M
