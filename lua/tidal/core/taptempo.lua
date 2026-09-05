local config = require("tidal.config")
local message = require("tidal.core.message")
local state = require("tidal.core.state")

local M = {}

local taps = {}
local subbeats = 0
local active = false
local win = nil
local buf = nil
local timer = nil
local last_tap_time = nil
local display_cps = nil
local tap_ns = nil
local time_sig_num = nil
local time_sig_denom = nil
local bpm = nil
local target_buf = nil
local cps_sent = false

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
  local viz_win = viz.get_window()
  if viz_win and vim.api.nvim_win_is_valid(viz_win) then
    local cfg = vim.api.nvim_win_get_config(viz_win)
    local viz_top = cfg.row - 1
    row = viz_top - p_opts.height - 2
  end
  return math.max(row, 0)
end

local function infer_denominator(numerator)
  if numerator >= 6 and numerator % 3 == 0 then
    return 8
  end
  return 4
end

local BIG_DIGITS = {
  ["0"] = { "███", "█ █", "█ █", "█ █", "███" },
  ["1"] = { " █ ", "██ ", " █ ", " █ ", "███" },
  ["2"] = { "███", "  █", "███", "█  ", "███" },
  ["3"] = { "███", "  █", "███", "  █", "███" },
  ["4"] = { "█ █", "█ █", "███", "  █", "  █" },
  ["5"] = { "███", "█  ", "███", "  █", "███" },
  ["6"] = { "███", "█  ", "███", "█ █", "███" },
  ["7"] = { "███", "  █", "  █", "  █", "  █" },
  ["8"] = { "███", "█ █", "███", "█ █", "███" },
  ["9"] = { "███", "█ █", "███", "  █", "███" },
  ["/"] = { "  █", "  █", " █ ", "█  ", "█  " },
  [":"] = { "   ", " █ ", "   ", " █ ", "   " },
  [" "] = { "   ", "   ", "   ", "   ", "   " },
}

local function big_lines(str)
  local out = {}
  for row = 1, 5 do
    local line = {}
    for i = 1, #str do
      local ch = str:sub(i, i)
      local glyph = BIG_DIGITS[ch] or BIG_DIGITS[" "]
      if #line > 0 then
        table.insert(line, " ")
      end
      table.insert(line, glyph[row])
    end
    table.insert(out, table.concat(line))
  end
  return out
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

local function update_time_sig()
  if #taps > 0 then
    time_sig_num = 1 + subbeats
    time_sig_denom = infer_denominator(time_sig_num)
  end
end

local function send_cps(cps)
  if not cps or cps_sent then
    return
  end
  cps_sent = true
  message.tidal.send_line(string.format("setcps %f", cps))
  state.current_cps = cps
  state.current_bpm = bpm
  state.current_time_sig_num = time_sig_num
  state.current_time_sig_denom = time_sig_denom
end

function record_tap()
  local opts = config.options.taptempo

  table.insert(taps, vim.uv.now())
  if #taps > opts.max_taps then
    table.remove(taps, 1)
  end
  subbeats = 0

  if check_outlier_exit() then
    M.deactivate()
    return
  end

  last_tap_time = vim.uv.now()
  update_time_sig()

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
  if time_sig_num then
    bpm = display_cps * 60 * time_sig_num
  end
  send_cps(display_cps)
  redraw()
end

function record_subtap()
  subbeats = subbeats + 1
  last_tap_time = vim.uv.now()
  update_time_sig()
  if display_cps and time_sig_num then
    bpm = display_cps * 60 * time_sig_num
  end
  redraw()
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
  M.reposition()
end

function M.reposition()
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end
  local width = math.min(popup_opts().width, ui.width - 4)
  local col = ui.width - width - 2
  vim.api.nvim_win_set_config(win, { relative = "editor", row = get_popup_row(), col = col })

  local viz = require("tidal.core.visualizer")
  if viz.get_window() then
    viz.reposition()
  end
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

  local bpm_str = "--"
  if bpm then
    bpm_str = string.format("%.0f", bpm)
  end
  local time_str = "?/?"
  if time_sig_num then
    time_str = string.format("%d/%d", time_sig_num, time_sig_denom)
  end

  local function centered(lines)
    local out = {}
    local width = 0
    for _, l in ipairs(lines) do
      if #l > width then
        width = #l
      end
    end
    local pad_total = content_width - width
    local left = math.floor(pad_total / 2)
    local right = pad_total - left
    if left < 0 then
      left = 0
    end
    if right < 0 then
      right = 0
    end
    local lp = string.rep(" ", left)
    local rp = string.rep(" ", right)
    for _, l in ipairs(lines) do
      table.insert(out, lp .. l .. rp)
    end
    return out
  end

  local bpm_digit_lines = big_lines(bpm_str == "--" and "---" or bpm_str)
  local time_digit_lines = big_lines(time_str == "?/?" and "---" or time_str)

  local rows = {}

  local label_bpm = " BPM " .. string.rep(" ", 0)
  table.insert(rows, label_bpm .. string.rep(" ", content_width - #label_bpm))
  for _, l in ipairs(centered(bpm_digit_lines)) do
    table.insert(rows, l)
  end

  table.insert(rows, string.rep(" ", content_width))

  local label_time = " TIME "
  table.insert(rows, label_time .. string.rep(" ", content_width - #label_time))
  for _, l in ipairs(centered(time_digit_lines)) do
    table.insert(rows, l)
  end

  table.insert(rows, string.rep(" ", content_width))

  local elapsed = last_tap_time and (vim.uv.now() - last_tap_time) or (p_opts.flash_ms + 1)
  local ripple = string.rep(" ", content_width)
  if elapsed <= p_opts.flash_ms and not bpm then
    local anim_width = p_opts.anim_width
    local progress = elapsed / p_opts.flash_ms
    local head_col = math.floor(progress * anim_width)
    local left_pad = math.floor((content_width - anim_width) / 2)
    local chars = {}
    for _ = 1, content_width do
      table.insert(chars, " ")
    end
    for c = 0, head_col - 1 do
      chars[left_pad + c + 1] = "█"
    end
    ripple = table.concat(chars)
  end
  table.insert(rows, ripple)

  local tap_count_str = string.format("%d", math.min(#taps, config.options.taptempo.max_taps))
  local counter_line = string.format("  taps: %s", tap_count_str)
  counter_line = counter_line .. string.rep(" ", content_width - #counter_line)
  table.insert(rows, counter_line)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rows)
  vim.api.nvim_buf_clear_namespace(buf, tap_ns, 0, -1)

  if bpm then
    for r = 1, 5 do
      vim.api.nvim_buf_add_highlight(buf, tap_ns, "TidalRippleTapHead", r, 0, content_width)
    end
  end
  if time_sig_num then
    for r = 1, 5 do
      vim.api.nvim_buf_add_highlight(buf, tap_ns, "TidalRippleTapHead", 7 + r, 0, content_width)
    end
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
  subbeats = 0
  display_cps = nil
  last_tap_time = nil
  time_sig_num = nil
  time_sig_denom = nil
  bpm = nil
  cps_sent = false
  setup_namespace()
  create_window()
  if not win then
    active = false
    return
  end
  start_timer()
  target_buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "n", record_tap, { buffer = target_buf, desc = "Tap tempo downbeat" })
  vim.keymap.set("n", "m", record_subtap, { buffer = target_buf, desc = "Tap tempo subbeat" })
  redraw()
end

function M.deactivate()
  if not active then
    return
  end
  active = false
  send_cps(display_cps)
  local tgt = target_buf
  target_buf = nil
  if tgt and vim.api.nvim_buf_is_valid(tgt) then
    pcall(vim.keymap.del, "n", "n", { buffer = tgt })
    pcall(vim.keymap.del, "n", "m", { buffer = tgt })
  end
  stop_timer()
  close_window()
  if tgt and vim.api.nvim_buf_is_valid(tgt) then
    pcall(vim.api.nvim_set_current_buf, tgt)
  end
  taps = {}
  subbeats = 0
  display_cps = nil
  last_tap_time = nil
  time_sig_num = nil
  time_sig_denom = nil
  bpm = nil
  cps_sent = false
end

function M.reset()
  taps = {}
  subbeats = 0
  display_cps = nil
  last_tap_time = nil
  time_sig_num = nil
  time_sig_denom = nil
  bpm = nil
  cps_sent = false
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

function M.get_time_sig()
  if time_sig_num then
    return { numerator = time_sig_num, denominator = time_sig_denom }
  end
  return nil
end

function M.get_bpm()
  return bpm
end

return M
