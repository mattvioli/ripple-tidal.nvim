local api = require("tidal.api")
local config = require("tidal.config")
local message = require("tidal.core.message")
local notify = require("tidal.util.notify")
local toggle = require("tidal.core.toggle")

local Tidal = {}

local keymaps = {
  send_line = { callback = api.send_line, desc = "Send current line to tidal" },
  send_visual = {
    callback = [[<Esc><Cmd>lua require("tidal").api.send_visual()<CR>gv]],
    desc = "Send current visual selection to tidal",
  },
  send_block = { callback = api.send_block, desc = "Send current block to tidal" },
  send_node = { callback = api.send_node, desc = "Send current TS node to tidal" },
  send_silence = { callback = api.send_silence, desc = "Send 'd{count} silence' to tidal" },
  send_hush = { callback = api.send_hush, desc = "Send 'hush' to tidal" },
  show_meter = { callback = api.show_meter, desc = "Show SuperCollider meter window" },
  show_scope = { callback = api.show_scope, desc = "Show SuperCollider scope window" },
  show_tree = { callback = api.show_tree, desc = "Show SuperCollider node tree" },
  toggle_osc = { callback = api.toggle_osc, desc = "Toggle OSC listener" },
  toggle_visualizer = { callback = api.toggle_visualizer, desc = "Toggle visualizer floating window" },
  toggle_taptempo = { callback = api.toggle_taptempo, desc = "Toggle tap tempo mode" },
}

local function setup_user_commands()
  vim.api.nvim_create_user_command("TidalLaunch", function()
    api.launch_tidal(config.options.boot)
  end, { desc = "Launch Tidal instance" })

  vim.api.nvim_create_user_command("TidalQuit", api.exit_tidal, { desc = "Quit Tidal instance" })

  vim.api.nvim_create_user_command("TidalToggle", toggle.toggle_ghci, { desc = "Toggle Tidal REPL window" })

  vim.api.nvim_create_user_command("TidalHush", api.send_hush, { desc = "Hush all Tidal patterns" })

  vim.api.nvim_create_user_command("TidalSilence", function(opts)
    local n = tonumber(opts.args) or vim.v.count
    message.tidal.send_line(string.format("d%d silence", n))
  end, { nargs = "?", desc = "Silence a Tidal pattern (default: d0)" })

  vim.api.nvim_create_user_command("TidalOSCToggle", api.toggle_osc, { desc = "Toggle OSC listener" })
  vim.api.nvim_create_user_command("TidalVisualizerToggle", api.toggle_visualizer, { desc = "Toggle visualizer floating window" })
  vim.api.nvim_create_user_command("TidalTapTempo", api.toggle_taptempo, { desc = "Toggle tap tempo mode" })
  vim.api.nvim_create_user_command("TidalTapTempoReset", api.reset_taps, { desc = "Reset tap tempo history" })
end

local function setup_autocmds()
  vim.api.nvim_create_augroup("TidalRipple", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = "TidalRipple",
    pattern = { "*.tidal" },
    callback = function()
      vim.api.nvim_set_option_value("filetype", "haskell", { buf = 0 })
      if config.options.auto_launch then
        api.ensure_launched()
      end
      for name, mapping in pairs(config.options.mappings or {}) do
        if mapping then
          local command = keymaps[name]
          vim.keymap.set(mapping.mode, mapping.key, command.callback, { buffer = true, desc = command.desc })
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "Filetype" }, {
    group = "TidalRipple",
    pattern = { "supercollider" },
    callback = function()
      for name, mapping in pairs(config.options.mappings or {}) do
        if mapping then
          local command = keymaps[name]
          vim.keymap.set(mapping.mode, mapping.key, command.callback, { buffer = true, desc = command.desc })
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    group = "TidalRipple",
    callback = function()
      require("tidal.core.taptempo").deactivate()
      api.exit_tidal()
    end,
  })
end

local MIN_VERSION = "0.10.0"

function Tidal.setup(options)
  if vim.fn.has("nvim-" .. MIN_VERSION) == 0 then
    notify.error("tidal-ripple.nvim requires nvim >= " .. MIN_VERSION)
    return
  end
  config.setup(options)
  setup_autocmds()
  setup_user_commands()
end

Tidal.api = api

return Tidal
