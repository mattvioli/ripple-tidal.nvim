local config = require("tidal.config")
local message = require("tidal.core.message")
local state = require("tidal.core.state")

local M = {}

local taps = {}
local active = false
local callback_id = nil

local CR_KEY = vim.keycode("<CR>")
local ESC_KEY = vim.keycode("<Esc>")

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

  return 1.0 / avg_interval_s
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

  if #taps < opts.min_taps then
    vim.notify(string.format("Tap tempo: %d/%d taps", #taps, opts.min_taps), vim.log.levels.INFO)
    return
  end

  local cps = calculate_cps()
  if not cps then
    return
  end

  send_cps(cps)
  local bpm = cps * 60 * 4
  vim.notify(string.format("Tap tempo: CPS %.3f (BPM %.1f)", cps, bpm), vim.log.levels.INFO)

  if #taps >= opts.max_taps then
    M.deactivate()
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
  callback_id = vim.on_key(on_key)
  vim.notify("Tap tempo active. Press <CR> in rhythm. <Esc> to exit.", vim.log.levels.INFO)
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
  vim.notify("Tap tempo deactivated", vim.log.levels.INFO)
end

function M.reset()
  taps = {}
end

function M.is_active()
  return active
end

function M.get_cps()
  return calculate_cps()
end

function M.get_tap_count()
  return #taps
end

return M
