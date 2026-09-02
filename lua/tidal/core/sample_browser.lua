local config = require("tidal.config")
local state = require("tidal.core.state")
local sample_data = require("tidal.data.sample_banks")

local M = {}

local win = nil
local buf = nil
local view_stack = {} -- stack of { type = "banks"|"files", bank = string }
local user_overrides = {}

local function load_user_overrides()
  local ok, result = pcall(dofile, vim.fn.stdpath("config") .. "/tidal-ripple/sample_descriptions.lua")
  if ok and type(result) == "table" then
    user_overrides = result
  else
    user_overrides = {}
  end
end

local function get_description(bank)
  if user_overrides[bank] then
    return user_overrides[bank]
  end
  local info = sample_data.banks[bank]
  if info then
    return info.description
  end
  return ""
end

local function get_opts()
  return config.options.sample_browser
end

function M.is_open()
  return state.sample_browser_open or false
end

local function create_window()
  local opts = get_opts()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end

  local width = math.floor(ui.width * opts.width_ratio)
  width = math.max(width, 30)
  local height = ui.height - 2

  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 1,
    col = ui.width - width - 1,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border,
  })
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat")

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", M.close, map_opts)
  vim.keymap.set("n", "<Esc>", M.close, map_opts)
  vim.keymap.set("n", "<BS>", M.go_back, map_opts)
  vim.keymap.set("n", "<CR>", M.investigate, map_opts)
  vim.keymap.set("n", "<leader>i", M.investigate, map_opts)
end

function M.open()
  if state.sample_browser_open then
    return
  end
  load_user_overrides()
  view_stack = { { type = "banks" } }
  create_window()
  if not win then
    return
  end
  state.sample_browser_open = true
  M.render()
end

function M.close()
  if not state.sample_browser_open then
    return
  end
  state.sample_browser_open = false
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
  buf = nil
  view_stack = {}
end

function M.toggle()
  if state.sample_browser_open then
    M.close()
  else
    M.open()
  end
end

function M.go_back()
  if not state.sample_browser_open or not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if #view_stack > 1 then
    table.remove(view_stack)
    M.render()
  end
end

function M.investigate()
  if not state.sample_browser_open or not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_idx = cursor[1] - 1 -- 0-indexed
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  if line_idx < 0 or line_idx >= #lines then
    return
  end

  local current_view = view_stack[#view_stack]
  if current_view.type == "banks" then
    -- Extract bank name from the current line
    local line = lines[line_idx + 1]
    local bank = line:match("^%s*(%S+)")
    if bank and sample_data.banks[bank] then
      local files = sample_data.get_files(bank)
      if #files > 0 then
        table.insert(view_stack, { type = "files", bank = bank })
        M.render()
      end
    end
  end
end

function M.render()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local current_view = view_stack[#view_stack]
  local lines = {}

  if current_view.type == "banks" then
    local banks = sample_data.get_banks()
    local header = string.format("Sample Banks (%d)", #banks)
    table.insert(lines, header)
    table.insert(lines, string.rep("─", #header))
    table.insert(lines, "")

    for _, b in ipairs(banks) do
      local desc = get_description(b.name)
      local desc_display = desc ~= "" and ("  " .. desc) or ""
      local count_str = string.format("[%d]", b.file_count)
      table.insert(lines, string.format("%-20s %s %s", b.name, desc_display, count_str))
    end

    table.insert(lines, "")
    table.insert(lines, string.rep("─", #header))
    table.insert(lines, "<CR>/<leader>i investigate  |  <BS> back  |  q close")
  elseif current_view.type == "files" then
    local bank = current_view.bank
    local files = sample_data.get_files(bank)
    local desc = get_description(bank)

    local header = string.format("%s (%d files)", bank, #files)
    table.insert(lines, "← " .. header)
    if desc ~= "" then
      table.insert(lines, "  " .. desc)
    end
    table.insert(lines, string.rep("─", 40))
    table.insert(lines, "")

    for i, fname in ipairs(files) do
      table.insert(lines, string.format("  %s", fname))
    end

    table.insert(lines, "")
    table.insert(lines, string.rep("─", 40))
    table.insert(lines, "<BS> back  |  q close")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

return M
