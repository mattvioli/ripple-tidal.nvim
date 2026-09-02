local config = require("tidal.config")
local message = require("tidal.core.message")
local state = require("tidal.core.state")

local M = {}

local taps = {}
local active = false
local callback_id = nil
local win = nil
local buf = nil
local timer = nil
local last_tap_time = nil
local display_cps = nil
local tap_ns = nil

local CR_KEY = vim.keycode("<CR>")
local ESC_KEY = vim.keycode("<Esc>")

local function popup_opts()
  return config.options.taptempo.popup
end

local function get_popup_row()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return 0
  end
  local p_opts = popup_opts()
  local row = ui.height - p_opts.height - 1
  local viz = require("tidal.core.visualizer")
  if viz.is_open() then
    row = row - config.options.visualizer.height - 1
  end
  return math.max(row, 0)
end

local function calculate_cps()
  local opts = config.options.taptempo
  if #taps < 2 then
    return nil
  end

  local intervals = {}
  for i = 2, #taps do
    table.insert(intervals, taps[i] - taps[i - 1])
  end

  local sorted = vim.deepcopy(intervals)
  table.sort(sorted)
  local median = sorted[math.ceil(#sorted / 2)]

  local filtered = {}
  for _, interval in ipairs(intervals) do
    if math.abs(interval - median) / median <= opts.outlier_threshold then
      table.insert(filtered, interval)
    end
  end

  if #filtered == 0 then
    return nil
  end

  local sum = 0
  for _, interval in ipairs(filtered) do
    sum = sum + interval
  end
  local avg_interval_s = (sum / #filtered) / 1000

  if avg_interval_s <= 0 then
    return nil
  end

  return 1.0 / avg_interval_s, median
end

local function check_outlier_exit()
  local opts = config.options.taptempo
  if #taps < 3 then
    return false
  end
  local latest = taps[#taps] - taps[#taps - 1]
  local intervals = {}
  for i = 2, #taps - 1 do
    table.insert(intervals, taps[i] - taps[i - 1])
  end
  local sorted = vim.deepcopy(intervals)
  table.sort(sorted)
  local median = sorted[math.ceil(#sorted / 2)]
  return latest > median * opts.exit_factor
end

local function on_key(key, _)
  if key == ESC_KEY then
    M.deactivate()
    return
  end

  if key ~= CR_KEY then
    return
  end

  record_tap()
end

local function send_cps(cps)
  message.tidal.send_line(string.format("setcps %f", cps))
  state.current_cps = cps
end

function record_tap()
  local opts = config.options.taptempo

  table.insert(taps, vim.uv.now())
  if #taps > opts.max_taps then
    table.remove(taps, 1)
  end

  if check_outlier_exit() then
    M.deactivate()
    return
  end

  last_tap_time = vim.uv.now()

  if #taps < opts.min_taps then
    redraw()
    return
  end

  local cps = calculate_cps()
  if not cps then
    redraw()
    return
  end

  display_cps = cps
  send_cps(cps)

  redraw()

  if #taps >= opts.max_taps then
    M.deactivate()
  end
end

local function setup_namespace()
  if not tap_ns then
    tap_ns = vim.api.nvim_create_namespace("TidalRippleTap")
  end
end

local function create_window()
  local p_opts = popup_opts()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end

  local width = math.min(p_opts.width, ui.width - 4)
  local height = p_opts.height

  buf = vim.api.nvim_create_buf(false, true)

  win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = get_popup_row(),
    col = ui.width - width - 2,
    width = width,
    height = height,
    style = "minimal",
    border = p_opts.border,
  })
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat")

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", M.deactivate, map_opts)
  vim.keymap.set("n", "<Esc>", M.deactivate, map_opts)
end

local function close_window()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
  buf = nil
end

local function start_timer()
  local p_opts = popup_opts()
  timer = vim.uv.new_timer()
  timer:start(p_opts.refresh_ms, p_opts.refresh_ms, vim.schedule_wrap(redraw))
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function redraw()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not active then
    return
  end

  local p_opts = popup_opts()
  local content_width = p_opts.width - 2

  local cps_str
  if display_cps then
    cps_str = string.format("%.3f", display_cps)
  else
    cps_str = "--"
  end

  local cps_line = string.format("  CPS: %s", cps_str)
  cps_line = cps_line .. string.rep(" ", content_width - #cps_line)

  local tap_count_str = string.format("%d/%d", math.min(#taps, p_opts.max_taps), p_opts.max_taps)
  local counter_line = string.format("  taps: %s", tap_count_str)
  local close_hint = "  [q]  "
  counter_line = counter_line .. string.rep(" ", content_width - #counter_line - #close_hint) .. close_hint

  local anim_width = p_opts.anim_width
  local anim_height = p_opts.anim_height
  local left_pad = math.floor((content_width - anim_width) / 2)

  local anim_lines = {}
  for _ = 1, anim_height do
    local row_chars = {}
    for _ = 1, content_width do
      table.insert(row_chars, " ")
    end
    table.insert(anim_lines, row_chars)
  end

  local elapsed = last_tap_time and (vim.uv.now() - last_tap_time) or (p_opts.flash_ms + 1)

  if elapsed <= p_opts.flash_ms then
    local progress = elapsed / p_opts.flash_ms
    local head_col = math.floor(progress * anim_width)

    for row = 0, anim_height - 1 do
      local chars = anim_lines[row + 1]
      for c = 0, anim_width - 1 do
        if c < head_col then
          local dist = head_col - c
          local char = "█"
          if dist <= 2 then
            chars[left_pad + c + 1] = char
          elseif dist <= 5 then
            chars[left_pad + c + 1] = char
          else
            chars[left_pad + c + 1] = char
          end
        end
      end
    end
  end

  local lines = {
    cps_line,
    string.rep(" ", content_width),
  }
  for _, row_chars in ipairs(anim_lines) do
    table.insert(lines, table.concat(row_chars))
  end
  table.insert(lines, string.rep(" ", content_width))
  table.insert(lines, counter_line)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, tap_ns, 0, -1)

  if elapsed <= p_opts.flash_ms then
    local progress = elapsed / p_opts.flash_ms
    local head_col = math.floor(progress * anim_width)

    for row = 0, anim_height - 1 do
      local line_idx = row + 2
      for c = 0, anim_width - 1 do
        if c < head_col then
          local dist = head_col - c
          local hl_name
          if dist <= 2 then
            hl_name = "TidalRippleTapHead"
          elseif dist <= 5 then
            hl_name = "TidalRippleTapMid"
          else
            hl_name = "TidalRippleTapTail"
          end
          local byte_pos = left_pad + c
          vim.api.nvim_buf_add_highlight(buf, tap_ns, hl_name, line_idx, byte_pos, byte_pos + 1)
        end
      end
    end
  end

  if display_cps then
    vim.api.nvim_buf_add_highlight(buf, tap_ns, "TidalRippleTapHead", 0, 2, 2 + #cps_str + 6)
  end
end

function M.toggle()
  if active then
    M.deactivate()
  else
    activate()
  end
end

function activate()
  if active then
    return
  end
  active = true
  taps = {}
  display_cps = nil
  last_tap_time = nil
  setup_namespace()
  create_window()
  if not win then
    active = false
    return
  end
  start_timer()
  callback_id = vim.on_key(on_key)
  redraw()
end

function M.deactivate()
  if not active then
    return
  end
  active = false
  if callback_id then
    pcall(vim.on_key, nil, callback_id)
    callback_id = nil
  end
  stop_timer()
  close_window()
  taps = {}
  display_cps = nil
  last_tap_time = nil
end

function M.reset()
  taps = {}
  display_cps = nil
  last_tap_time = nil
  redraw()
end

function M.is_active()
  return active
end

function M.get_cps()
  return display_cps
end

function M.get_tap_count()
  return #taps
end

function M.get_popup_height()
  return popup_opts().height
end

return M
