# tidal-ripple.nvim

Visually pleasing TidalCycles live coding for Neovim.

Fork of [grddavies/tidal.nvim](https://github.com/grddavies/tidal.nvim) with enhanced visualization, terminal management, and auto-boot.

## Features

- Inline eval: send lines, visual selections, blocks, and TS nodes to TidalCycles
- Auto-launch GHCi + SuperCollider on first send (opt-out)
- `:TidalToggle` — hide/show the GHCi terminal window
- `:TidalHush` / `:TidalSilence {n}` — stop patterns
- SuperCollider visual tools: `show_meter`, `show_scope`, `show_tree`
- Haskell syntax highlighting for `.tidal` files
- Flash-on-send highlight
- OSC-based cycle visualization _(planned)_
- Floating window visualizer _(planned)_

## Installation

### lazy.nvim

```lua
{
  "mvioli/tidal-ripple.nvim",
  opts = {
    -- See configuration section for defaults
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "haskell", "supercollider" } },
  },
}
```

## Configuration

```lua
{
  boot = {
    tidal = {
      cmd = "ghci",
      args = { "-v0" },
      file = vim.api.nvim_get_runtime_file("bootfiles/BootTidal.hs", false)[1],
      enabled = true,
    },
    sclang = {
      cmd = "sclang",
      args = {},
      file = vim.api.nvim_get_runtime_file("bootfiles/BootSuperDirt.scd", false)[1],
      enabled = true, -- boot sclang by default (set false to disable)
    },
    split = "h",
  },
  mappings = {
    send_line   = { mode = { "i", "n" }, key = "<S-CR>" },
    send_visual = { mode = { "x" },       key = "<S-CR>" },
    send_block  = { mode = { "i", "n", "x" }, key = "<M-CR>" },
    send_node   = { mode = "n",           key = "<leader><CR>" },
    send_silence = { mode = "n",          key = "<leader>d" },
    send_hush   = { mode = "n",           key = "<leader><Esc>" },
    show_meter  = { mode = { "n", "i", "x" }, key = "<F1>" },
    show_scope  = { mode = { "n", "i", "x" }, key = "<F2>" },
    show_tree   = { mode = { "n", "i", "x" }, key = "<F3>" },
  },
  selection_highlight = {
    highlight = { link = "IncSearch" },
    timeout = 150,
  },
  auto_launch = true,
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:TidalLaunch` | Start GHCi + SuperCollider |
| `:TidalQuit` | Stop all processes |
| `:TidalToggle` | Show/hide the GHCi terminal window |
| `:TidalHush` | Silence all patterns |
| `:TidalSilence {n}` | Silence pattern d{n} (default: d1) |

## Boot file

The plugin bundles `bootfiles/BootTidal.hs` and `bootfiles/BootSuperDirt.scd`. To use a custom boot file, set `boot.tidal.file` or `boot.sclang.file` in your config. The plugin also searches the project directory for `BootTidal.hs` as a fallback.

## Related

- [grddavies/tidal.nvim](https://github.com/grddavies/tidal.nvim) — original fork base
- [jbfits/cycles.nvim](https://github.com/jbfits/cycles.nvim) — SC visual tools
- [tidalcycles/vim-tidal](https://github.com/tidalcycles/vim-tidal) — original Vim plugin
