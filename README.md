# tidal-ripple.nvim

Visually pleasing TidalCycles live coding for Neovim.

Fork of [grddavies/tidal.nvim](https://github.com/grddavies/tidal.nvim) with enhanced visualization, terminal management, auto-boot, autocomplete, a sample browser, and TidalLooper integration.

## Features

- Inline eval: send lines, visual selections (incl. `Ctrl-V` blocks), blocks, and TS nodes to TidalCycles
- Auto-launch GHCi + SuperCollider on first send (opt-out)
- Sends are queued until the REPL is ready, so boot races can't lose lines
- A warning (once) if you try to send while no REPL is running
- `:TidalToggle` — hide/show the GHCi terminal window
- `:TidalHush` / `:TidalSilence {n}` — stop patterns
- SuperCollider visual tools: `show_meter`, `show_scope`, `show_tree`
- Haskell syntax highlighting for `.tidal` files; keymaps for `.scd` (SuperCollider) buffers
- Flash-on-send highlight
- Playhead sign markers (`▶`) on sent lines, flashing in time with OSC cycle feedback
- Statusline component showing live CPS / BPM / cycle / time signature
- Floating-window beat grid visualizer, per-orbit, with configurable colors (toggle with `:TidalVisualizerToggle` or `<leader>v`)
- Tap tempo with BPM + time-signature inference (toggle with `:TidalTapTempo` or `<leader>t`)
- Sample bank browser — all 218 Dirt-Samples banks with descriptions and file listings (`:TidalSampleBrowser` or `<leader>a`)
- Context-aware autocomplete — pattern functions, control params, sample banks/indices, keywords, and user symbols (nvim-cmp source or omnifunc)
- **TidalLooper integration** — live sampling via SuperDirt (default off, enable with `boot.looper.enabled = true`)
- Bundled `Looper.scd` boot file for TidalLooper

## Prerequisites

- A TidalCycles install: `ghci` with the Tidal library (`stack`/`cabal`/`ghcup`, see [tidalcycles.org](https://tidalcycles.org))
- SuperCollider with the SuperDirt quark
- JACK (optional but recommended) — the plugin can auto-detect your soundcard and spawn `jackd`
- `nvim-treesitter` (haskell parser) for best autocomplete, `nvim-cmp` for the cmp backend
- Neovim `>= 0.10`

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
      osc_target = {          -- second OSC target for visualization
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
    port = 5050,      -- must match boot.tidal.osc_target.port
    enabled = true,   -- start the OSC listener after launch
    debug = false,    -- log every /dirt/play message at DEBUG level
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
      divisions = 4,        -- beats per cycle
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
    backend = "cmp",    -- "cmp" (nvim-cmp, default) or "omnifunc"
    source_name = "tidal",
  },
  taptempo = {
    min_taps = 2,          -- taps before BPM is sent (setcps)
    max_taps = 16,
    outlier_threshold = 0.3, -- tap-interval outliers are discarded
    exit_factor = 3.0,       -- a late tap 3x the median exits tap mode
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

## Keymaps

All keymaps are defined per-buffer (installed on `.tidal` and `.scd` buffers) and can be
rebound or removed via `mappings.<name> = nil`.

| Key           | Mode      | Action                                         |
| ------------- | --------- | ---------------------------------------------- |
| `<S-CR>`      | i, n      | Send current line to GHCi                      |
| `<S-CR>`      | x         | Send visual selection (incl. `Ctrl-V` block)            |
| `<M-CR>`      | i, n, x   | Send contiguous non-empty block                |
| `<leader><CR>`| n         | Send tree-sitter node under cursor             |
| `<leader>d`   | n         | Send `d{count} silence` (count prefix = orbit) |
| `<leader><Esc>`| n        | Send `hush` (silence all patterns)             |
| `<F1>`        | n, i, x   | SuperCollider `s.meter`                        |
| `<F2>`        | n, i, x   | SuperCollider `s.scope`                        |
| `<F3>`        | n, i, x   | SuperCollider `s.plotTree`                     |
| `<leader>o`   | n         | Toggle the OSC listener                        |
| `<leader>v`   | n         | Toggle the beat grid visualizer                |
| `<leader>t`   | n         | Toggle tap tempo                               |
| `<leader>a`   | n         | Toggle the sample browser                      |
| `<leader>i`   | n         | Investigate sample bank under cursor           |
| `<leader>lr`  | n         | Looper: record (count prefix = orbit)          |
| `<leader>lo`  | n         | Looper: overdub                                |
| `<leader>lf`  | n         | Looper: free buffer (count prefix = buffer)    |
| `<leader>lF`  | n         | Looper: free all buffers                       |
| `<leader>lm`  | n         | Looper: cycle mode replace ↔ overdub           |
| `<leader>lp`  | n         | Looper: persist loops to disk                  |

## Commands

| Command                               | Description                                              |
| ------------------------------------- | -------------------------------------------------------- |
| `:TidalLaunch`                        | Start GHCi + SuperCollider                               |
| `:TidalQuit`                          | Stop all processes                                       |
| `:TidalToggle`                        | Show/hide the GHCi terminal window                       |
| `:TidalHush`                          | Silence all patterns                                     |
| `:TidalSilence {n}`                   | Silence pattern d{n} (default/`count` = orbit)           |
| `:TidalOSCToggle`                     | Toggle OSC cycle listener                                |
| `:TidalVisualizerToggle`              | Toggle beat grid visualizer floating window              |
| `:TidalTapTempo`                      | Toggle tap tempo mode                                    |
| `:TidalTapTempoReset`                 | Reset tap tempo history                                  |
| `:TidalSampleBrowser`                 | Toggle sample bank browser                               |
| `:TidalSampleInvestigate`             | Investigate sample bank under cursor                     |
| `:TidalLooperRecord`                  | Record loop on current orbit (count = orbit, default d1) |
| `:TidalLooperOverdub`                 | Overdub loop on current orbit                            |
| `:TidalLooperFree {n}`                | Free loop buffer n                                       |
| `:TidalLooperFreeAll`                 | Free all loop buffers                                    |
| `:TidalLooperPersist {name}`          | Persist loops to disk                                    |
| `:TidalLooperMode {replace\|overdub}` | Set looper mode                                          |
| `:TidalLooperInput {port}`            | Set looper input port                                    |

## Usage

Open a `.tidal` file, put a pattern on one line, and evaluate:

- `<S-CR>` sends the line under the cursor — flash-on-send highlights it, and a `▶`
  playhead marker is placed next to it. The marker flashes in time with the actual
  audio via OSC `/dirt/play` feedback.
- `<leader><Esc>` hush, `<leader>d` silence a single orbit.
- `.scd` buffers route the same send keys to sclang instead.
- With `auto_launch = true` (default), the first send boots GHCi and SuperCollider
  automatically. GHCi and SC boot files are loaded with sends queued until each
  interpreter is ready, so a slow boot never drops evaluation.

## Visualizer

A floating beat grid that tracks each orbit's events in real time. Open with
`:TidalVisualizerToggle` or `<leader>v`; close with `q`/`<Esc>` or toggle again.

- Events are fed by the OSC listener (`/dirt/play`), so it needs Tidal to be running
  with the OSC target configured (`boot.tidal.osc_target`).
- Each event gets a color from `visualizer.palette` (per sound); markers advance
  across the grid as cycles tick.
- Tunables: window `width`/`height`/`border`, `refresh_interval_ms`, grid
  `divisions` (beats/cycle), `chars_per_beat`, and limits
  `max_orbits`/`max_events_per_orbit`.

The OSC listener on port 5050 also feeds the statusline and playhead flash. Toggle it
independently with `:TidalOSCToggle` (`<leader>o`).

## Statusline

A live component showing CPS, cycle, BPM, and time signature. Add it to your statusline
with:

```lua
-- lualine example
require('lualine').setup {
  sections = { lualine_x = { { function() return require('tidal.core.statusline').get_status() end } } },
}

-- built-in statusline example
vim.o.statusline = "%!v:lua.require('tidal.core.statusline').get_status()"
```

The `statusline.format` option supports placeholders: `{cps}`, `{cycle}`, `{bpm}`,
`{timesig}`. Values come from the OSC listener, so it shows live data while a pattern
is running.

## Tap tempo

`:TidalTapTempo` or `<leader>t` opens a popup with big BPM and time-signature digits.
While tap mode is active, in the target buffer:

- `n` — tap the downbeat
- `m` — tap a sub-beat (infers the time signature, e.g. 4/4, 3/4, 6/8)

Once enough taps are in (`taptempo.min_taps`, default 2) the BPM is sent as `setcps`.
Outlier intervals are discarded, and a late tap more than `taptempo.exit_factor` times
the median interval exits tap mode. `:TidalTapTempoReset` clears the history. The
inferred BPM / time signature also feeds the statusline.

## Sample browser

Browse the Dirt-Samples banks shipped with SuperDirt — all 218 banks, each with its
description and file listing. Open with `:TidalSampleBrowser` or `<leader>a`.

- `<CR>` / `<leader>i` — drill into the selected bank's file listing
- `<BS>` — go back one level
- `q` / `<Esc>` — close

`<leader>i` (or `:TidalSampleInvestigate`) also works from a `.tidal` buffer to look up
the sample bank under the cursor.

Overriding descriptions: create `~/.config/nvim/tidal-ripple/sample_descriptions.lua`
returning a table of `bank_name = "description"` pairs, e.g.

```lua
return { bd = "my favourite kick", hh = "" }
```

This overrides (or blanks) the descriptions bundled in `lua/tidal/data/sample_banks.lua`.
The bundled file is regenerated by `scripts/update_sample_data.lua` (requires `curl`).

## Autocomplete

Context-aware autocomplete for Tidal patterns, enabled by default. Two backends:

- **nvim-cmp** (default) — registers a source named `tidal` (`completion.source_name`).
  With lazy.nvim you don't need to configure sources; if you configure them manually,
  add `{ name = "tidal" }`.
- **omnifunc** — used when nvim-cmp isn't available, or when
  `completion.backend = "omnifunc"`. Sets `omnifunc` on `.tidal` buffers and triggers
  automatically via `<C-x><C-o>` / a debounced popup while typing.

What it completes, based on cursor context:

- Sample bank names inside `s"..."` (e.g. `s"<here>` → `bd`, `cp`, `808`, ...)
- Sample indices / letters inside `n"..."`
- Control parameters after `#` (e.g. `# <here>` → `cps`, `pan`, `vowel`, ...)
- Pattern functions after `$` (e.g. `d1 $ <here>` → `slow`, `rev`, `every`, ...)
- Tidal keywords, orbit aliases (`d0`–`d9`, `p`), oscillators
- Your own symbols: `let x = ...`, `p "name"`, and bare assignments scanned from the buffer

Best results with nvim-treesitter's haskell parser installed; without it the plugin falls
back to a regex-based parser (a one-time notice is shown).

## Audio setup (JACK)

On boot, the plugin parses `/proc/asound/cards`, and:

- if there's a single card, it's used automatically;
- if there are several, `vim.ui.select` prompts you to pick one;
- then `jackd -d alsa -d hw:<card>` is spawned (with retries and `jack_wait`), unless
  `boot.sclang.soundcard` is set to skip the prompt / detection.

Useful options:

| Option                    | Effect                                              |
| ------------------------- | --------------------------------------------------- |
| `boot.sclang.kill_jack`   | Stop any running jackd before starting a new one    |
| `boot.sclang.soundcard`   | e.g. `"hw:0"` — skip detection/prompt entirely      |
| `boot.sclang.pre_cmd`     | Shell command run before sclang starts              |

If JACK isn't available, SuperCollider manages audio itself and a warning is shown.

## Boot file

The plugin bundles `bootfiles/BootTidal.hs`, `bootfiles/BootSuperDirt.scd`, and
`bootfiles/Looper.scd` (used when TidalLooper is enabled). `BootTidal.hs` starts the
Tidal stream on your usual SuperDirt target *plus* a second OSC target
(`127.0.0.1:5050`) that feeds the visualizer/statusline/playhead.

- Customize with `boot.tidal.file` / `boot.sclang.file`.
- The plugin also searches the project directory for `BootTidal.hs` as a fallback.
- Boot evaluation is queued until the interpreter signals readiness, then flushed.

## Looper (TidalLooper)

The plugin integrates [thgrund/tidal-looper](https://github.com/thgrund/tidal-looper)
for live sampling via SuperDirt. Enable it with `boot.looper.enabled = true`.

When enabled, the boot process starts SuperDirt with an explicit `~dirt` variable and
loads the looper synths (`rlooper`, `olooper`, `slooper`, `freeLoops`, `persistLoops`).

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

For the built-in help run `:h tidal-ripple`.

- [grddavies/tidal.nvim](https://github.com/grddavies/tidal.nvim) — original fork base
- [jbfits/cycles.nvim](https://github.com/jbfits/cycles.nvim) — SC visual tools
- [tidalcycles/vim-tidal](https://github.com/tidalcycles/vim-tidal) — original Vim plugin

## TODO

- [ ] Test looper integration end-to-end
- [ ] Support multiple time signatures across bars in a single tap tempo session
- [ ] Auto-write a TidalCycles orbit pattern to the main buffer based on detected time signature