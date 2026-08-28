local boot = require("tidal.core.boot")
local message = require("tidal.core.message")
local notify = require("tidal.util.notify")
local select = require("tidal.util.select")
local state = require("tidal.core.state")
local util = require("tidal.util")
local config = require("tidal.config")

local M = {}

function M.ensure_launched()
  if state.launched then
    return
  end
  if state.launching then
    return
  end
  state.launching = true
  local opts = config.options.boot
  local current_win = vim.api.nvim_get_current_win()
  if opts.tidal.enabled then
    boot.tidal(opts.tidal, opts.split)
  end
  if opts.sclang.enabled then
    local sclang_split = opts.tidal.enabled and opts.split == "h" and "v" or opts.split
    boot.sclang(opts.sclang, sclang_split, function()
      vim.api.nvim_set_current_win(current_win)
      state.launched = true
      state.launching = false
    end)
  else
    vim.api.nvim_set_current_win(current_win)
    state.launched = true
    state.launching = false
  end
end

function M.launch_tidal(args)
  local current_win = vim.api.nvim_get_current_win()
  if state.launched then
    notify.warn("Tidal is already running")
    return
  end
  if state.launching then
    return
  end
  state.launching = true
  if args.tidal.enabled then
    boot.tidal(args.tidal, args.split)
  end
  if args.sclang.enabled then
    local sclang_split = args.tidal.enabled and args.split == "h" and "v" or args.split
    boot.sclang(args.sclang, sclang_split, function()
      vim.api.nvim_set_current_win(current_win)
      state.launched = true
      state.launching = false
    end)
  else
    vim.api.nvim_set_current_win(current_win)
    state.launched = true
    state.launching = false
  end
end

function M.exit_tidal()
  if not state.launched then
    notify.warn("Tidal is not running. Launch with ':TidalLaunch'")
    return
  end
  for _, proc in ipairs({ state.ghci, state.sclang }) do
    if proc then
      proc:exit()
    end
  end
  state.launched = false
  state.launching = false
  state.ghci = nil
  state.ghci_win = nil
  state.ghci_buf = nil
  state.sclang = nil
  state.sclang_win = nil
  state.sclang_buf = nil
end

local function ft_to_repl()
  local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  if ft == "supercollider" then
    return message.sclang
  end
  return message.tidal
end

function M.send(text)
  local repl = ft_to_repl()
  if repl then
    repl.send_line(text)
  end
end

function M.send_silence()
  message.tidal.send_line(string.format("d%d silence", vim.v.count1))
end

function M.send_hush()
  message.tidal.send_line("hush")
end

function M.send_multiline(lines)
  local repl = ft_to_repl()
  if repl then
    repl.send_multiline(lines)
  end
end

function M.send_line()
  if config.options.auto_launch then
    M.ensure_launched()
  end
  local line = select.get_current_line()
  local text = line.lines[1]
  if #text > 0 then
    require("tidal.core.highlight").apply_highlight(line.start, line.finish)
    local repl = ft_to_repl()
    if repl then
      repl.send_line(text)
    end
  end
end

function M.send_visual()
  if config.options.auto_launch then
    M.ensure_launched()
  end
  local visual = select.get_visual()
  if visual then
    require("tidal.core.highlight").apply_highlight(visual.start, visual.finish)
    local repl = ft_to_repl()
    if repl then
      repl.send_multiline(visual.lines)
    end
  end
end

function M.send_block()
  if config.options.auto_launch then
    M.ensure_launched()
  end
  if util.is_empty(vim.api.nvim_get_current_line()) then
    return
  end
  local block = select.get_block()
  require("tidal.core.highlight").apply_highlight(block.start, block.finish)
  local repl = ft_to_repl()
  if repl then
    repl.send_multiline(block.lines)
  end
end

function M.send_node()
  if config.options.auto_launch then
    M.ensure_launched()
  end
  local block = select.get_node()
  if block then
    require("tidal.core.highlight").apply_highlight(block.start, block.finish)
    local repl = ft_to_repl()
    if repl then
      repl.send_multiline(block.lines)
    end
  end
end

function M.show_meter()
  if state.sclang and state.sclang:is_running() then
    state.sclang:send_line("s.meter")
  end
end

function M.show_scope()
  if state.sclang and state.sclang:is_running() then
    state.sclang:send_line("s.scope")
  end
end

function M.show_tree()
  if state.sclang and state.sclang:is_running() then
    state.sclang:send_line("s.plotTree")
  end
end

return M
