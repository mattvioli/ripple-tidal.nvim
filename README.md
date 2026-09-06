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
- Keymaps also available in `.scd` (SuperCollider) buffers
- Flash-on-send highlight
- Playhead sign markers (`▶`) on sent lines
- Statusline component showing live CPS / cycle info
- OSC-based cycle visualization (toggle with `:TidalOSCToggle`)
- Floating window beat grid visualizer (toggle with `:TidalVisualizerToggle` or `<leader>v`)
- Tap tempo (toggle with `:TidalTapTempo` or `<leader>t`)
- Sample bank browser — browsable Dirt-Samples banks with descriptions and file listings (`:TidalSampleBrowser` or `<leader>a`)
- Context-aware autocomplete — Tidal pattern functions, control params, sample banks/indices, keywords, and user symbols
- **TidalLooper integration** — live sampling via SuperDirt (default off, enable with `boot.looper.enabled = true`)
- Bundled `Looper.scd` boot file for TidalLooper
- All visualization features are opt-in — enable them via the toggle commands or keymaps

## Installation

### lazy.nvim

```lua
{
  "mattvioli/ripple-tidal.nvim",
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
      enabled = true,     -- boot sclang by default (set false to disable)
      kill_jack = true,   -- stop existing jackd before starting
      soundcard = nil,    -- auto-detect; set e.g. "hw:0" to skip prompt
      pre_cmd = nil,      -- command to run before sclang starts
    },
    looper = {
      enabled = false,       -- set true to enable TidalLooper
      num_buffers = 8,       -- number of loop buffers per bank
      p_level = 0.0,         -- 0.0 = replace, 1.0 = overdub
      r_level = 2.5,         -- recording level
      default_input = 0,     -- default audio input port
      default_name = "loop", -- default sample bank name
      persist_path = "~/Music/Loops/", -- path for persisted loops
      debug_mode = false,
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
    toggle_osc        = { mode = "n", key = "<leader>o" },
    toggle_visualizer = { mode = "n", key = "<leader>v" },
    toggle_taptempo   = { mode = "n", key = "<leader>t" },
    looper_record     = { mode = "n", key = "<leader>lr" },
    looper_overdub    = { mode = "n", key = "<leader>lo" },
    looper_free       = { mode = "n", key = "<leader>lf" },
    looper_free_all   = { mode = "n", key = "<leader>lF" },
    looper_mode_cycle = { mode = "n", key = "<leader>lm" },
    looper_persist    = { mode = "n", key = "<leader>lp" },
    toggle_sample_browser = { mode = "n", key = "<leader>a" },
    investigate_sample    = { mode = "n", key = "<leader>i" },
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
    format = "♩ {cps} CPS | c.{cycle}",
  },
  visualizer = {
    width = 60,
    height = 12,
    border = "single",
    refresh_interval_ms = 33,
    grid = {
      divisions = 4,
      total_cycles = 1,
      chars_per_beat = 8,
    },
    palette = {
      "#FF6B6B", "#51CF66", "#FFD43B", "#339AF0",
      "#CC5DE8", "#20C997", "#F06595", "#FF922B",
    },
    max_orbits = 8,
    max_events_per_orbit = 4,
  },
  sample_browser = {
    width_ratio = 0.33,
    border = "single",
  },
  auto_launch = true,
  completion = {
    enabled = true,
    backend = "cmp",       -- "cmp" (nvim-cmp) or "omnifunc"
    source_name = "tidal",
  },
  taptempo = {
    min_taps = 2,
    max_taps = 16,
    outlier_threshold = 0.3,
    exit_factor = 3.0,
    idle_ms = 1000,
    popup = {
      width = 22,
      height = 16,
      border = "single",
      flash_ms = 150,
      refresh_ms = 50,
      anim_width = 12,
      anim_height = 3,
    },
  },
}
```

## Commands

| Command                               | Description                                              |
| ------------------------------------- | -------------------------------------------------------- |
| `:TidalLaunch`                        | Start GHCi + SuperCollider                               |
| `:TidalQuit`                          | Stop all processes                                       |
| `:TidalToggle`                        | Show/hide the GHCi terminal window                       |
| `:TidalHush`                          | Silence all patterns                                     |
| `:TidalSilence {n}`                   | Silence pattern d{n} (default: d0)                       |
| `:TidalOSCToggle`                     | Toggle OSC cycle listener                                |
| `:TidalVisualizerToggle`              | Toggle beat grid visualizer floating window              |
| `:TidalTapTempo`                      | Toggle tap tempo mode (press `<CR>` in rhythm)           |
| `:TidalTapTempoReset`                 | Reset tap tempo history                                  |
| `:TidalSampleBrowser`                 | Toggle sample bank browser                               |
| `:TidalSampleInvestigate`             | Investigate sample bank under cursor                     |
| `:TidalLooperRecord`                  | Record loop on current orbit (count = orbit, default d1) |
| `:TidalLooperOverdub`                 | Overdub loop on current orbit                            |
| `:TidalLooperFree {n}`                | Free loop buffer n                                       |
| `:TidalLooperFreeAll`                 | Free all loop buffers                                    |
| `:TidalLooperPersist {name}`          | Persist loops to disk                                    |
| `:TidalLooperMode {replace\|overdub}` | Set looper mode                          |
| `:TidalLooperInput {port}`            | Set looper input port                    |

## Sample browser

Browse the Dirt-Samples banks shipped with SuperDirt. Open with `:TidalSampleBrowser` or `<leader>a`. Each bank shows its description and file count; press `<CR>` or `<leader>i` to drill into the file listing, `<BS>` to go back, `q`/`<Esc>` to close.

Overriding descriptions: create `~/.config/nvim/tidal-ripple/sample_descriptions.lua` returning a table of `bank_name = "description"` pairs. This overrides the descriptions bundled in `lua/tidal/data/sample_banks.lua`.

| Key          | Action                                              |
| ------------ | --------------------------------------------------- |
| `<leader>a`  | Toggle sample bank browser                          |
| `<leader>i`  | Investigate sample bank under cursor / drill into    |
| `<CR>`       | Drill into the selected bank's file listing         |
| `<BS>`       | Go back one level                                   |
| `q` / `<Esc>`| Close the browser                                   |

## Autocomplete

Context-aware autocomplete for Tidal patterns, enabled by default. Two backends:

- **nvim-cmp** (default) — registers a `tidal` source (name configurable via `completion.source_name`). No source config needed if you use `lazy.nvim`; if you configure sources manually, add `{ name = "tidal" }`.
- **omnifunc** fallback — used when nvim-cmp isn't available, or when `completion.backend = "omnifunc"`. Sets `omnifunc` on `.tidal` buffers and triggers automatically on `<C-x><C-o>` / a debounced popup while typing.

What it completes, based on cursor context:

- Sample bank names inside `s"..."` (e.g. `s"<here>` → `bd`, `cp`, `808`, ...)
- Sample indices / letters inside `n"..."`
- Control parameters after `#` (e.g. `# <here>` → `cps`, `pan`, `vowel`, ...)
- Pattern functions after `$` (e.g. `d1 $ <here>` → `slow`, `rev`, `every`, ...)
- Tidal keywords, orbit aliases (`d0`–`d9`, `p`), oscillators
- Your own symbols: `let x = ...`, `p "name"`, and bare assignments scanned from the buffer

Best results with nvim-treesitter's haskell parser installed; without it the plugin falls back to a regex-based parser (a one-time notice is shown).

## Boot file

The plugin bundles `bootfiles/BootTidal.hs`, `bootfiles/BootSuperDirt.scd`, and `bootfiles/Looper.scd` (used when TidalLooper is enabled). To use a custom boot file, set `boot.tidal.file` or `boot.sclang.file` in your config. The plugin also searches the project directory for `BootTidal.hs` as a fallback.

## Looper (TidalLooper)

The plugin integrates [thgrund/tidal-looper](https://github.com/thgrund/tidal-looper) for live sampling via SuperDirt. Enable it with `boot.looper.enabled = true`.

When enabled, the boot process starts SuperDirt with an explicit `~dirt` variable and loads the looper synths (`rlooper`, `olooper`, `slooper`, `freeLoops`, `persistLoops`).

### Basic usage

Once the looper is loaded, evaluate these patterns in a `.tidal` buffer:

```haskell
-- Record one cycle to buffer 0 on orbit 1
d1 $ s "rlooper"

-- Play back the loop
d1 $ s "loop"

-- Overdub onto buffer 0
d1 $ s "olooper"

-- Cycle through buffers
d1 $ s "rlooper" # n "<0 1 2 3>"
d1 $ s "loop" # n "[0,1,2,3]"

-- Free all loop buffers
once $ s "freeLoops"

-- Persist loops to disk
once $ s "persistLoops" # lname "loop"
```

### Keymaps

| Key          | Action                                                                             |
| ------------ | ---------------------------------------------------------------------------------- |
| `<leader>lr` | Record loop on current orbit (use count prefix for orbit, e.g. `2<leader>lr` = d2) |
| `<leader>lo` | Overdub loop on current orbit                                                      |
| `<leader>lf` | Free loop buffer (use count prefix for buffer number)                              |
| `<leader>lF` | Free all loop buffers                                                              |
| `<leader>lm` | Cycle looper mode (replace ↔ overdub)                                             |
| `<leader>lp` | Persist loops to disk                                                              |

### Commands

| Command                               | Description                              |
| ------------------------------------- | ---------------------------------------- |
| `:TidalLooperRecord`                  | Record loop (count = orbit, default d1)  |
| `:TidalLooperOverdub`                 | Overdub loop (count = orbit, default d1) |
| `:TidalLooperFree {n}`                | Free loop buffer n                       |
| `:TidalLooperFreeAll`                 | Free all loop buffers                    |
| `:TidalLooperPersist {name}`          | Persist loops to disk                    |
| `:TidalLooperMode {replace\|overdub}` | Set looper mode                          |
| `:TidalLooperInput {port}`            | Set looper input port                    |

## Related

- [grddavies/tidal.nvim](https://github.com/grddavies/tidal.nvim) — original fork base
- [jbfits/cycles.nvim](https://github.com/jbfits/cycles.nvim) — SC visual tools
- [tidalcycles/vim-tidal](https://github.com/tidalcycles/vim-tidal) — original Vim plugin

## TODO

- [ ] Test looper integration end-to-end
- [ ] Support multiple time signatures across bars in a single tap tempo session
- [ ] Auto-write a TidalCycles orbit pattern to the main buffer based on detected time signature
