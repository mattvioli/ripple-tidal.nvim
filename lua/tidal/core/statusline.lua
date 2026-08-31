local config = require("tidal.config")
local state = require("tidal.core.state")

local M = {}

function M.get_status()
  if not config.options.statusline.enabled then
    return ""
  end

  local cps = state.current_cps
  local cycle = state.current_cycle

  if not cps or not cycle then
    return ""
  end

  local cycle_str = string.format("%.1f", cycle)

  local fmt = config.options.statusline.format
  fmt = fmt:gsub("{cycle}", cycle_str)
  fmt = fmt:gsub("{cps}", string.format("%.3f", cps))

  return fmt
end

return M
