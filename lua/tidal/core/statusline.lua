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

  if state.current_bpm then
    fmt = fmt:gsub("{bpm}", string.format("%.0f", state.current_bpm))
  else
    fmt = fmt:gsub("{bpm}", "--")
  end

  if state.current_time_sig_num and state.current_time_sig_denom then
    fmt = fmt:gsub("{timesig}", string.format("%d/%d", state.current_time_sig_num, state.current_time_sig_denom))
  else
    fmt = fmt:gsub("{timesig}", "?/?")
  end

  return fmt
end

return M
