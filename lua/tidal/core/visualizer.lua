local config = require("tidal.config")
local state = require("tidal.core.state")

local M = {}

local win = nil
local buf = nil
local timer = nil
local events = {}
local frame_count = 0
local viz_ns = nil
local sound_colors = {}
local next_color = 1

local function setup_highlights()
  viz_ns = vim.api.nvim_create_namespace("TidalRippleViz")
  local opts = config.options.visualizer
  for i, color in ipairs(opts.palette) do
    vim.api.nvim_set_hl(0, "TidalRippleViz" .. i, { fg = color, default = true })
  end
end

local function get_opts()
  return config.options.visualizer
end

function M.is_open()
  return state.visualizer_open
end

function M.add_event(parsed)
  if not state.visualizer_open then
    return
  end
  local opts = get_opts()
  local orbit = tonumber(parsed.orbit)
  if not orbit or orbit >= opts.max_orbits then
    return
  end
  if not events[orbit] then
    events[orbit] = {}
  end
  local sound = parsed.sound or ""
  if not sound_colors[sound] then
    sound_colors[sound] = next_color
    next_color = next_color + 1
  end
  local color_idx = sound_colors[sound]
  local list = events[orbit]
  table.insert(list, {
    delta = parsed.delta,
    cycle = parsed.cycle,
    sound = sound,
    frame = frame_count,
    color = color_idx,
  })
  if #list > opts.max_events_per_orbit then
    table.remove(list, 1)
  end
end

local function create_window()
  local opts = get_opts()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end

  local width = math.min(opts.width, ui.width - 4)
  local height = opts.height

  buf = vim.api.nvim_create_buf(false, true)

  local row = ui.height - height - 1

  win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = ui.width - width - 2,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border,
  })
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat")

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", M.close, map_opts)
  vim.keymap.set("n", "<Esc>", M.close, map_opts)
end

local function start_timer()
  local opts = get_opts()
  timer = vim.uv.new_timer()
  timer:start(opts.refresh_interval_ms, opts.refresh_interval_ms, vim.schedule_wrap(M.redraw))
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function M.get_window()
  return win
end

function M.reposition()
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end
  local width = math.min(get_opts().width, ui.width - 4)
  local row = ui.height - vim.api.nvim_win_get_height(win) - 1
  local col = ui.width - width - 2
  vim.api.nvim_win_set_config(win, { relative = "editor", row = math.max(row, 0), col = col })
end

function M.open()
  if state.visualizer_open then
    return
  end
  setup_highlights()
  create_window()
  if not win then
    return
  end
  state.visualizer_open = true
  start_timer()
  M.redraw()
  local taptempo = require("tidal.core.taptempo")
  pcall(taptempo.reposition)
end

function M.close()
  if not state.visualizer_open then
    return
  end
  state.visualizer_open = false
  stop_timer()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
  buf = nil
  events = {}
  sound_colors = {}
  next_color = 1
  frame_count = 0
  local taptempo = require("tidal.core.taptempo")
  pcall(taptempo.reposition)
end

function M.toggle()
  if state.visualizer_open then
    M.close()
  else
    M.open()
  end
end

function M.redraw()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not state.visualizer_open then
    return
  end

  frame_count = frame_count + 1
  local opts = get_opts()
  local cps = state.current_cps or 0
  local anim_offset = (frame_count * opts.refresh_interval_ms / 1000 * cps) % 1.0
  local cycle = tonumber(state.current_cycle) or 0
  local total_pos = opts.grid.divisions * opts.grid.total_cycles * opts.grid.chars_per_beat

  local orbit_data = {}
  for orbit, list in pairs(events) do
    local markers = {}
    local orbit_color = nil
    for _, ev in ipairs(list) do
      local elapsed = (frame_count - ev.frame) * (opts.refresh_interval_ms / 1000) * cps
      if elapsed < 1.0 then
        local pos_01 = (ev.cycle % 1.0 + anim_offset) % 1.0
        local col = math.floor(pos_01 * total_pos)
        table.insert(markers, { col = col, color = ev.color })
        if not orbit_color then
          orbit_color = ev.color
        end
      end
    end
    if #markers > 0 then
      table.insert(orbit_data, { orbit = orbit, markers = markers, color = orbit_color })
    end
  end

  table.sort(orbit_data, function(a, b)
    return a.orbit < b.orbit
  end)

  local lines = {}
  local header = string.format(" ⚡ Beat Grid  |  CPS %.3f  |  Cycle %.1f", cps, cycle)
  table.insert(lines, header)
  table.insert(lines, string.rep("─", #header))

  local line_map = {}
  for _, od in ipairs(orbit_data) do
    local orbit = od.orbit
    local label = string.format(" %-2d │", orbit)
    local grid_chars = {}
    for _ = 1, total_pos do
      table.insert(grid_chars, "·")
    end
    for _, m in ipairs(od.markers) do
      if m.col >= 0 and m.col < total_pos then
        grid_chars[m.col + 1] = m.col == 0 and "⬤" or "●"
      end
    end
    local grid_str = table.concat(grid_chars)
    local track = label .. grid_str .. "│"
    table.insert(lines, track)
    line_map[orbit] = #lines - 1

    od.byte_offsets = {}
    od.char_widths = {}
    local byte_pos = #label
    for i = 1, total_pos do
      od.byte_offsets[i] = byte_pos
      local w = #grid_chars[i]
      od.char_widths[i] = w
      byte_pos = byte_pos + w
    end
  end

  if #orbit_data == 0 then
    local padding = string.rep(" ", total_pos)
    table.insert(lines, " │" .. padding .. "│")
  end

  table.insert(lines, string.rep("─", #header))
  table.insert(lines, string.format(" [q] close  |  %d orbit(s) active", #orbit_data))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, viz_ns, 0, -1)

  for _, od in ipairs(orbit_data) do
    local line_idx = line_map[od.orbit]
    if line_idx then
      local label = string.format(" %-2d │", od.orbit)
      local label_len = #label
      if od.color then
        local hl_idx = ((od.color - 1) % #opts.palette) + 1
        vim.api.nvim_buf_add_highlight(buf, viz_ns, "TidalRippleViz" .. hl_idx, line_idx, 0, label_len)
      end
      for _, m in ipairs(od.markers) do
        local hl_idx = ((m.color - 1) % #opts.palette) + 1
        local idx = m.col + 1
        local byte_pos = od.byte_offsets[idx]
        local byte_end = byte_pos + od.char_widths[idx]
        vim.api.nvim_buf_add_highlight(buf, viz_ns, "TidalRippleViz" .. hl_idx, line_idx, byte_pos, byte_end)
      end
    end
  end
end

return M
