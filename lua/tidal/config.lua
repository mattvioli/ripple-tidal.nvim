local M = {}

local defaults = {
  boot = {
    tidal = {
      cmd = "ghci",
      args = { "-v0" },
      file = vim.api.nvim_get_runtime_file("bootfiles/BootTidal.hs", false)[1],
      enabled = true,
      osc_target = {
        enabled = true,
        port = 5050,
        address = "127.0.0.1",
        latency = 0.2,
      },
    },
    sclang = {
      cmd = "sclang",
      args = {},
      file = vim.api.nvim_get_runtime_file("bootfiles/BootSuperDirt.scd", false)[1],
      enabled = true,
      kill_jack = true,
      soundcard = nil,
      pre_cmd = nil,
    },
    split = "h",
  },
  mappings = {
    send_line = { mode = { "i", "n" }, key = "<S-CR>" },
    send_visual = { mode = { "x" }, key = "<S-CR>" },
    send_block = { mode = { "i", "n", "x" }, key = "<M-CR>" },
    send_node = { mode = "n", key = "<leader><CR>" },
    send_silence = { mode = "n", key = "<leader>d" },
    send_hush = { mode = "n", key = "<leader><Esc>" },
    show_meter = { mode = { "n", "i", "x" }, key = "<F1>" },
    show_scope = { mode = { "n", "i", "x" }, key = "<F2>" },
    show_tree = { mode = { "n", "i", "x" }, key = "<F3>" },
    toggle_osc = { mode = "n", key = "<leader>o" },
  },
  selection_highlight = {
    highlight = { link = "IncSearch" },
    timeout = 150,
  },
  osc = {
    port = 5050,
    enabled = true,
  },
  playhead = {
    enabled = true,
    highlight = { link = "TidalRipplePlayhead" },
  },
  statusline = {
    enabled = true,
    format = "♩ {bpm} BPM | c.{cycle}",
  },
  auto_launch = true,
}

M.options = defaults

M.namespace = vim.api.nvim_create_namespace("TidalRipple")
M.playhead_ns = vim.api.nvim_create_namespace("TidalRipplePlayhead")

vim.api.nvim_set_hl(0, "TidalRipplePlayhead", { link = "CursorLine" })

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
