# tidal-ripple.nvim — Post-Audit TODO

## Completed

- [x] Save findings as todo.md
- [x] Fix config/doc drift
- [x] Document undocumented features (sample browser, autocomplete)
- [x] Commit and push config/doc changes

## Functional Gaps

- [ ] **Playhead OSC integration** — `lua/tidal/core/playhead.lua` `on_cycle()` is empty. `▶` markers placed on send, not cycle-driven. (Iteration 2 claim)
- [ ] **Silent-send warning** — sends vanish silently when `auto_launch = false` and no REPL running. No user feedback.
- [ ] **sclang boot handshake race** — no readiness check; can fail on slow machines.

## Data Gaps

- [ ] **Sample bank file listings** — ~180 banks described but only ~18 have file data. Re-run `scripts/update_sample_data.lua` (requires `curl` + `jq`).

## Cleanup

- [ ] **Dead state** — `state.looper_loaded` is written in `boot.lua` but never read.
- [ ] **`iterations.md` stale** — many Iteration-1 items marked `[ ]` are actually implemented.
- [ ] **Blockwise visual selection** — explicit non-feature (`util/select.lua` raises error).
- [ ] **OSC dispatch logging** — logs every `/dirt/play` at DEBUG level (noisy).
- [ ] **Redundant ftdetect** — both `ftdetect/tidal.lua` and `init.lua` set `filetype=haskell`.

## Notes

- README install path says `mattvioli/ripple-tidal.nvim` but plugin is `tidal-ripple.nvim`
- `min_taps`: code defaults to `2`, README documents `4`
- Completion feature exists but is undocumented in README
- Sample browser (`:TidalSampleBrowser`, `<leader>a`, `<leader>i`) undocumented
