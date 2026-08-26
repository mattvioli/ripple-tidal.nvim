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

- [ ] `core/osc.lua` — UDP socket listener on port 5050
- [ ] Parse incoming `/dirt/play` OSC messages (extract `cycle`, `cps`, `orbit`, `delta`)
- [ ] Calculate current beat within cycle from `cycle` + `cps`
- [ ] Replace flash-on-send with extmark highlighting driven by OSC timing
- [ ] Modify bundled `BootTidal.hs` to add second OSC target pointing to `127.0.0.1:5050`
- [ ] Auto-configure boot file to include visualizer target
- [ ] Statusline component showing current CPS / BPM / cycle

## Iteration 3 — Floating Window Visualizer

**Goal**: Dedicated visualizer window with live beat grid, per-orbit tracking.

- [ ] `core/visualizer.lua` — floating window with configurable size/position
- [ ] Beat grid display: colored markers per orbit moving across the grid
- [ ] Real-time updates via `vim.uv` timer + OSC data
- [ ] Configurable colors, shapes, grid divisions
- [ ] Optional: send visualizer data to external window (like DPV) via OSC
