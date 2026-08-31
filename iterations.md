# tidal-ripple.nvim — Iterations

## Iteration 1 — Core Eval + Boot Management

**Goal**: Reliable inline eval with terminal management, matching vim-tidal's feature set.

- [x] Fork `grddavies/tidal.nvim` as base, rename to `tidal-ripple.nvim`
- [ ] `:TidalToggle` — hide/show GHCi terminal window (buffer stays, process stays alive)
- [ ] `:TidalHush` — send `hush` to Tidal
- [ ] `:TidalSilence {n}` — send `d{n} silence` to Tidal
- [ ] Auto-launch GHCi + sclang on first send (if not already launched)
- [ ] sclang boot enabled by default (opt-out via `boot.sclang.enabled = false`)
- [ ] `show_meter` / `show_scope` / `show_tree` keymaps + commands (from cycles.nvim)
- [ ] Boot file: bundled `bootfiles/BootTidal.hs` as default, user override via `boot.tidal.file`
- [ ] Haskell syntax highlighting for `.tidal` files (set `filetype=haskell`)
- [ ] Flash-on-send highlight (150ms, already in base)

**Keymaps** (same as tidal.nvim):
| Mode | Key | Action |
|------|-----|--------|
| n, i | `<S-CR>` | Send current line |
| x | `<S-CR>` | Send visual selection |
| n, i, x | `<M-CR>` | Send block (contiguous non-empty lines) |
| n | `<leader><CR>` | Send TS node under cursor |
| n | `<leader>d` | Send `d{count} silence` |
| n | `<leader><Esc>` | Send `hush` |

## Iteration 2 — OSC Listening + Cycle-Based Visualization

**Goal**: Real-time beat tracking via Tidal's OSC output, driving line highlighting.

- [x] `core/osc.lua` — UDP socket listener on port 5050
- [x] Parse incoming `/dirt/play` OSC messages (extract `cycle`, `cps`, `orbit`, `delta`)
- [x] Calculate current beat within cycle from `cycle` + `cps`
- [x] Replace flash-on-send with extmark highlighting driven by OSC timing
- [x] Modify bundled `BootTidal.hs` to add second OSC target pointing to `127.0.0.1:5050`
- [x] Auto-configure boot file to include visualizer target
- [x] Statusline component showing current CPS / BPM / cycle

## Iteration 3 — Floating Window Visualizer

**Goal**: Dedicated visualizer window with live beat grid, per-orbit tracking.

- [x] `core/visualizer.lua` — floating window with configurable size/position
- [x] Beat grid display: colored markers per orbit moving across the grid
- [x] Real-time updates via `vim.uv` timer + OSC data
- [x] Configurable colors, shapes, grid divisions
- [x] Optional: send visualizer data to external window (like DPV) via OSC
