local Ghci = require("tidal.util.repl.ghci")
local Sclang = require("tidal.util.repl.sclang")
local state = require("tidal.core.state")
local config = require("tidal.config")

local M = {}

function M.tidal(opts, split)
  if not opts.enabled then
    return
  end
  state.ghci = Ghci:new({
    name = "tidal",
    cmd = opts.cmd,
    args = vim.list_extend({
      "-XOverloadedStrings",
      "-ghci-script=" .. vim.fn.expand(opts.file),
    }, opts.args or {}),
    on_exit = function(_code, _signal)
      state.ghci = nil
      state.ghci_win = nil
    end,
  })
  local win_opts = { split = split or config.options.boot.split or "h" }
  state.ghci:start(win_opts)
  state.ghci_buf = state.ghci.buf.bufnr
  state.ghci_win = state.ghci.win_id
end

function M.sclang(opts, split)
  if not opts.enabled then
    return
  end
  state.sclang = Sclang:new({
    name = "sclang",
    cmd = opts.cmd,
    args = vim.list_extend({}, opts.args or {}),
    on_exit = function(_code, _signal)
      state.sclang = nil
      state.sclang_win = nil
    end,
  })
  local win_opts = { split = split or config.options.boot.split or "h" }
  state.sclang:start(win_opts)
  state.sclang_buf = state.sclang.buf.bufnr
  state.sclang_win = state.sclang.win_id
  local file = vim.fn.expand(opts.file)
  state.sclang:send_line('"' .. file .. '".load;')
end

return M
