local state = require("tidal.core.state")

local M = {}

function M.hide_ghci()
  if state.ghci_win and vim.api.nvim_win_is_valid(state.ghci_win) then
    vim.api.nvim_win_close(state.ghci_win, true)
    state.ghci_win = nil
  end
end

function M.show_ghci()
  if state.ghci and state.ghci.buf and state.ghci.buf.bufnr then
    local bufnr = state.ghci.buf.bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    vim.cmd("split")
    state.ghci_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.ghci_win, bufnr)
  end
end

function M.toggle_ghci()
  if state.ghci_win and vim.api.nvim_win_is_valid(state.ghci_win) then
    M.hide_ghci()
  else
    M.show_ghci()
  end
end

function M.hide_sclang()
  if state.sclang_win and vim.api.nvim_win_is_valid(state.sclang_win) then
    vim.api.nvim_win_close(state.sclang_win, true)
    state.sclang_win = nil
  end
end

function M.show_sclang()
  if state.sclang and state.sclang.buf and state.sclang.buf.bufnr then
    local bufnr = state.sclang.buf.bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    vim.cmd("split")
    state.sclang_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.sclang_win, bufnr)
  end
end

function M.toggle_sclang()
  if state.sclang_win and vim.api.nvim_win_is_valid(state.sclang_win) then
    M.hide_sclang()
  else
    M.show_sclang()
  end
end

return M
