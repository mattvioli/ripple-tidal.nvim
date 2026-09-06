# tidal-ripple.nvim — Post-Audit TODO

## Completed

- [x] Save findings as todo.md
- [x] Fix config/doc drift
- [x] Document undocumented features (sample browser, autocomplete)
- [x] Commit and push config/doc changes
- [x] **Playhead OSC integration** — `on_cycle()` now flashes markers driven by `/dirt/play` timing (`parsed.delta`), with `TidalRippleFlash` highlight
- [x] **Silent-send warning** — `message.lua` warns once when sending to a REPL that isn't running (suppressed while launching)
- [x] **sclang boot handshake** — REPL base queues sends until the interpreter prints output (20s timeout fallback)
- [x] **Dead state removed** — `state.looper_loaded` was written but never read

## Functional Gaps

None — all three audited gaps are fixed.

## Data Gaps

- [x] **Sample bank file listings** — regenerated via git trees API (single request, no rate limiting): all 218 banks now have file listings, 2,038 files total (was 18 banks/203 files). Improved description parser for `:N` suffixes and direct `d1 "bank"` form.

## Cleanup (nice-to-have)

- [ ] **`README` install path** — plugin named `tidal-ripple.nvim`, local dir matches; GitHub remote is `ripple-tidal.nvim`. Consider renaming repo or README for consistency.
- [ ] **Blockwise visual selection** — explicit non-feature (`util/select.lua` raises error). Implement `<C-v>` block sends if desired.
- [ ] **OSC dispatch logging** — logs every `/dirt/play` at DEBUG level (noisy).
- [ ] **Redundant ftdetect** — both `ftdetect/tidal.lua` and `init.lua` set `filetype=haskell`.
- [ ] **Config default** — `min_taps` now aligned (config + README = 2).

## Notes

- `BootTidal.hs` top-level `let` triggers a false-positive LSP parse error; it is valid GHCi script syntax.