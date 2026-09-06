# tidal-ripple.nvim Feature Reference

A detailed explanation of every feature in tidal-ripple.nvim, organized by category.

For a hands-on walkthrough see [tutorial.md](tutorial.md).

---

## Table of Contents

1. [Code Evaluation](#1-code-evaluation)
2. [Auto-Launch & Boot Management](#2-auto-launch--boot-management)
3. [Visual Feedback](#3-visual-feedback)
4. [OSC Integration](#4-osc-integration)
5. [Beat Grid Visualizer](#5-beat-grid-visualizer)
6. [Statusline Component](#6-statusline-component)
7. [Tap Tempo](#7-tap-tempo)
8. [Sample Browser](#8-sample-browser)
9. [Autocomplete](#9-autocomplete)
10. [MIDI Controllers / /ctrl Values](#10-midi-controllers--ctrl-values)
11. [SuperCollider Tools](#11-supercollider-tools)
12. [TidalLooper (Live Sampling)](#12-tidallooper-live-sampling)
13. [Audio Setup (JACK)](#13-audio-setup-jack)
14. [Boot Files](#14-boot-files)
15. [Filetype Detection](#15-filetype-detection)

---

## 1. Code Evaluation

Send TidalCycles (or SuperCollider) code to the running interpreter directly from your buffer. tidal-ripple.nvim supports five evaluation modes, each mapping to different amounts of code.

### Send Line

`<S-CR>` (Shift+Enter) sends the line under the cursor to GHCi. This is the most common operation — write a pattern, press the key, hear it.

Available in **insert** and **normal** mode.

### Send Visual Selection

`<S-CR>` in **visual** mode sends the currently selected text, including `Ctrl-V` block selections (rectangular selections spanning multiple lines).

### Send Block

`<M-CR>` (Alt+Enter) sends the contiguous block of non-empty lines around the cursor. Useful for sending multi-line patterns like:

```haskell
d1 $ s "bd sn"
  # speed "2 4"
  # room 0.3
```

Available in insert, normal, and visual mode.

### Send Tree-Sitter Node

`<leader><CR>` sends the tree-sitter node under the cursor. Precise evaluation when you have nested expressions and want to run just one part.

### Send Silence / Send Hush

- `2<leader>d` — sends `d2 silence` (count prefix selects the orbit, defaults to d1)
- `<leader><Esc>` — sends `hush`, silencing all patterns

### Per-Filetype Routing

Evaluation routes based on the buffer filetype:
- `.tidal` buffers route sends to **GHCi**
- `.scd` (SuperCollider) buffers route the same keys to **sclang**

### Queued Sends

Sends are queued until the interpreter signals it is ready. This prevents boot races — a slow boot never drops evaluation.

### Auto-Launch on Send

With `auto_launch = true` (the default), the first send in a session automatically boots GHCi and SuperCollider. Set it to `false` to require a manual `:TidalLaunch`.

### Silent-Send Warning

If you try to send while no REPL is running (and auto-launch is disabled), a warning is shown once.

[Back to top](#table-of-contents)

---

## 2. Auto-Launch & Boot Management

### Manual Launch

`:TidalLaunch` boots GHCi (via `ghci -v0 -ghci-script=BootTidal.hs`) and sclang (`sclang BootSuperDirt.scd`) in terminal splits.

### REPL Window Management

- `:TidalToggle` — show/hide the GHCi terminal window
- The split direction is configurable (`boot.split = "h"` or `"v"`)

### Teardown

`:TidalQuit` stops all processes, kills the OSC listener, and clears playheads and highlights.

### Boot Orchestration

- Launches both GHCi and sclang (each independently enableable via `boot.tidal.enabled` / `boot.sclang.enabled`)
- Before loading the SuperDirt boot file, sends SC server options:
  ```lua
  s.options.numWireBufs = 128;
  s.options.numAudioBusChannels = 2048;
  s.options.device = "JACK";
  ```
- REPL submissions queue until each interpreter signals readiness (20s timeout), then flush

### Configuration

| Option                  | Default | Description                          |
|-------------------------|---------|--------------------------------------|
| `boot.tidal.cmd`        | `"ghci"`| Tidal REPL command                   |
| `boot.tidal.args`       | `{ "-v0" }` | Extra GHCi args                 |
| `boot.tidal.file`       | `"bootfiles/BootTidal.hs"` | GHCI boot script        |
| `boot.tidal.enabled`    | `true`  | Launch GHCi on startup               |
| `boot.sclang.cmd`       | `"sclang"` | SuperCollider command             |
| `boot.sclang.enabled`   | `true`  | Launch sclang on startup             |
| `boot.sclang.kill_jack` | `true`  | Stop running jackd before starting   |
| `boot.sclang.soundcard` | `nil`   | Auto-detect, or set `"hw:0"`         |
| `boot.sclang.pre_cmd`   | `nil`   | Command run before sclang starts     |
| `boot.split`            | `"h"`   | REPL split direction (`"h"`/`"v"`)   |

[Back to top](#table-of-contents)

---

## 3. Visual Feedback

tidal-ripple.nvim provides several layers of visual feedback so you can see what's happening while you code.

### Flash-on-Send

When you send code, the sent lines flash briefly using the `IncSearch` highlight group. Default duration is 150ms.

- Config: `selection_highlight.highlight` (group) and `selection_highlight.timeout` (ms)

### Playhead Markers

A `▶` sign appears in the sign column next to each line you've sent. The markers **flash in sync with the actual audio**, driven by OSC `/dirt/play` timing from TidalCycles.

- Flash duration derives from the event's `delta` value (clamped 80–500ms, fallback 200ms)
- Cleared per-orbit with `:TidalSilence {n}`, or all at once with `hush`
- Config: `playhead.enabled` and `playhead.highlight`

### Event Highlighting

Lines that are actively producing sound **flash in sync with the audio**, independent of the playhead. The plugin tracks which buffer lines correspond to which orbits, then flashes them when events fire for that orbit.

- Base flash duration default 400ms (the event's `delta` wins when present)
- Config: `event_highlight.enabled`, `event_highlight.highlight`, `event_highlight.fade_ms`

### Highlight Groups

| Group                   | Used for            |
|-------------------------|---------------------|
| `TidalRipplePlayhead`   | ▶ playhead markers  |
| `TidalRippleFlash`      | Marker flash state  |
| `TidalRippleEvent`      | Audio-synced flash  |
| `TidalRippleTapHead/Mid/Tail` | Tap tempo ripple |
| `TidalRippleViz1-8`     | Visualizer markers  |

All visual features require the OSC listener to be running (`:TidalOSCToggle` / `<leader>o`).

[Back to top](#table-of-contents)

---

## 4. OSC Integration

Bidirectional communication with TidalCycles over OSC.

### Incoming OSC (Listener, port 5050)

The plugin listens on UDP port 5050 using `vim.uv`/libuv and parses `/dirt/play` messages sent by TidalCycles (via the second OSC target configured in `BootTidal.hs`).

From each event it extracts: `cps`, `cycle`, `delta`, `sound`, `n`, `orbit`. These feed:

- The playhead flash
- Event highlighting
- The statusline
- The beat grid visualizer

It also handles **OSC bundles** (timetagged messages) via the bundled `losc` library, and receives `/ctrl` values (see [MIDI Controllers](#10-midi-controllers--ctrl-values)).

- Toggle: `:TidalOSCToggle` / `<leader>o`
- Debug: `osc.debug = true` logs every `/dirt/play` message

### Outgoing OSC (Sender, port 6010)

The plugin sends playback control to Tidal's OSC control input on port 6010 — no SuperCollider bridge needed:

| Action      | Key          | Command          | OSC message        |
|-------------|--------------|------------------|--------------------|
| Mute        | `<leader>m`  | `:TidalMute`     | `/mute`, `/muteAll`|
| Unmute      | `<leader>u`  | `:TidalUnmute`   | `/unmute`, `/unmuteAll` |
| Solo        | `<leader>s`  | `:TidalSolo`     | `/solo` (mutes all first) |
| Unsolo      | `<leader>S`  | `:TidalUnsolo`   | `/unsolo`, `/unsoloAll` |
| Hush        | `<leader>h`  | `:TidalHush`     | `/hush`            |
| /ctrl value | —            | `:TidalCtrlSend` | `/ctrl {key} {value}` |

Count prefixes select an orbit (e.g. `2<leader>m` mutes orbit 2); without a prefix, actions apply to all patterns. Named patterns work in commands too: `:TidalMute "bass"`.

### Configuration

| Option               | Default | Description                       |
|----------------------|---------|-----------------------------------|
| `osc.port`           | `5050`  | Listener port (must match `boot.tidal.osc_target.port`) |
| `osc.tidal_port`     | `6010`  | Tidal's OSC control input         |
| `osc.enabled`        | `true`  | Start OSC listener after launch   |
| `osc.debug`          | `false` | Log every `/dirt/play` at DEBUG   |
| `osc.ctrl_debug`     | `false` | Log every `/ctrl` at INFO         |

[Back to top](#table-of-contents)

---

## 5. Beat Grid Visualizer

A floating-window beat grid that tracks each orbit's events in real time.

### Usage

- Toggle: `:TidalVisualizerToggle` / `<leader>v`
- Close: `q` / `<Esc>` / toggle again

### What It Shows

- **Header** with live `CPS` (cycles per second) and `Cycle` position
- **Per-orbit rows** with markers advancing across a beat grid
- Markers are colored per-sound from `visualizer.palette` (8 colors)
- Animation offset computed from frame count × refresh interval × CPS, so it stays in sync with the audio

### Requirements

The visualizer is fed by the OSC listener (`/dirt/play`), so TidalCycles must be running with the OSC target configured (`boot.tidal.osc_target`).

### Configuration

| Option                      | Default | Description              |
|-----------------------------|---------|--------------------------|
| `visualizer.width`          | `60`    | Window width             |
| `visualizer.height`         | `12`    | Window height            |
| `visualizer.border`         | `"single"` | Border style          |
| `visualizer.refresh_interval_ms` | `33` | Redraw interval     |
| `visualizer.grid.divisions` | `4`     | Beats per cycle          |
| `visualizer.grid.total_cycles` | `1`  | Cycles on grid           |
| `visualizer.grid.chars_per_beat` | `8` | Chars per beat         |
| `visualizer.palette`        | 8 hex colors | Marker colors       |
| `visualizer.max_orbits`     | `8`     | Max orbits shown         |
| `visualizer.max_events_per_orbit` | `4` | Max events per orbit |

[Back to top](#table-of-contents)

---

## 6. Statusline Component

A live statusline component showing CPS (cycles per second), cycle position, BPM, and time signature.

### Integration

**lualine:**

```lua
require('lualine').setup {
  sections = {
    lualine_x = {
      { function() return require('tidal.core.statusline').get_status() end },
    },
  },
}
```

**Built-in statusline:**

```lua
vim.o.statusline = "%!v:lua.require('tidal.core.statusline').get_status()"
```

### Format Placeholders

| Placeholder | Description       |
|-------------|-------------------|
| `{cps}`     | Cycles per second |
| `{cycle}`   | Current cycle     |
| `{bpm}`     | Beats per minute  |
| `{timesig}` | Time signature    |

Default format: `"♩ {cps} CPS | c.{cycle}"`

### Configuration

| Option             | Default | Description                          |
|--------------------|---------|--------------------------------------|
| `statusline.enabled` | `true`| Show the component                   |
| `statusline.format` | `"♩ {cps} CPS \| c.{cycle}"` | Format string |

Values come from the OSC listener, so the component shows live data while a pattern is running. When no data is available, it returns an empty string.

[Back to top](#table-of-contents)

---

## 7. Tap Tempo

Determine BPM (and infer time signature) by tapping along with the music.

### Usage

1. Press `<leader>t` (or `:TidalTapTempo`) to open the tap tempo popup
2. In the target `.tidal` buffer:
   - `n` — tap the downbeat
   - `m` — tap a sub-beat (infers time signature)
3. Once enough taps are collected (`taptempo.min_taps`, default 2), the BPM is sent as `setcps`
4. The popup shows **big ASCII-art BPM and time signature digits** plus an animated "ripple" progress bar

### Time Signature Inference

The numerator is `1 + number of sub-beats`; the denominator is 8 if numerator ≥ 6 and evenly divisible by 3, otherwise 4. Supports 4/4, 3/4, 6/8, etc.

### Outlier Rejection & Exit

- Intervals more than `outlier_threshold` (default 0.3, i.e., 30%) from the median are discarded
- A late tap more than `exit_factor` (default 3.0) times the median interval exits tap mode
- `:TidalTapTempoReset` clears the history

The inferred BPM / time signature also feed the statusline.

### Configuration

| Option                    | Default | Description                       |
|---------------------------|---------|-----------------------------------|
| `taptempo.min_taps`       | `2`     | Taps before BPM is sent          |
| `taptempo.max_taps`       | `16`    | Max taps kept                     |
| `taptempo.outlier_threshold` | `0.3`| Discard outliers                |
| `taptempo.exit_factor`    | `3.0`   | Late tap exits mode (× median)   |
| `taptempo.popup.width`    | `22`    | Popup width                       |
| `taptempo.popup.height`   | `16`    | Popup height                      |
| `taptempo.popup.flash_ms` | `150`   | Ripple animation duration         |

[Back to top](#table-of-contents)

---

## 8. Sample Browser

Browse all 218 Dirt-Samples banks shipped with SuperDirt, each with its description and file listing.

### Usage

- Toggle: `:TidalSampleBrowser` / `<leader>a`
- `<CR>` / `<leader>i` — drill into the selected bank's file listing
- `<BS>` — go back one level
- `q` / `<Esc>` — close

### Investigate from Code

`<leader>i` (or `:TidalSampleInvestigate`) works from a `.tidal` buffer to look up the sample bank under the cursor. Place your cursor on `"bd"` in `s "bd sn"` and press `<leader>i` to see that bank's files.

### Sample Data

The bundled data lives in `lua/tidal/data/sample_banks.lua` (3,160 lines, 218 banks, 2,038 files) and is auto-generated by `scripts/update_sample_data.lua` (fetches from GitHub's Dirt-Samples repo; requires `curl`).

### Custom Descriptions

Override or blank descriptions by creating `~/.config/nvim/tidal-ripple/sample_descriptions.lua`:

```lua
return {
  bd = "my favourite kick",
  hh = "",   -- blank the bundled description
}
```

### Configuration

| Option                       | Default  | Description               |
|------------------------------|----------|---------------------------|
| `sample_browser.width_ratio` | `0.33`   | Fraction of editor width  |
| `sample_browser.border`      | `"single"` | Border style           |

[Back to top](#table-of-contents)

---

## 9. Autocomplete

Context-aware autocomplete for Tidal patterns, enabled by default.

### Two Backends

**nvim-cmp** (default): Registers a source named `tidal` (`completion.source_name`). With lazy.nvim no source config is needed; if configuring sources manually, add `{ name = "tidal" }`.

**omnifunc**: Used when nvim-cmp isn't installed, or when `completion.backend = "omnifunc"`. Sets `omnifunc` on `.tidal` buffers and triggers automatically via a debounced popup, or manually with `<C-x><C-o>`.

### Context-Based Completion

| Context        | Example        | Completions                      |
|----------------|----------------|----------------------------------|
| Sample names   | `s"<cursor>"`  | `bd`, `cp`, `808`, `jvbass`...  |
| Sample indices | `n"<cursor>"`  | `0`, `1`, `2`, ..., `a`, `b`... |
| Control params | `# <cursor>`   | `cps`, `pan`, `vowel`, `gain`...|
| Pattern funcs  | `d1 $ <cursor>`| `slow`, `rev`, `every`, `chop`..|
| Tidal keywords | `<cursor>`      | `hush`, `panic`, `setcps`, `d0`-`d16`, oscillators |
| User symbols   | `<cursor>`      | `let x = ...`, `p "name"`, bare assignments |

### Implementation Details

- **Context detection** uses nvim-treesitter's Haskell parser when available, with a regex-based fallback (a one-time notice is shown if treesitter is missing)
- A **mini-notation tokenizer** (`completion/mininotation.lua`) understands Tidal's mini-notation operators for context-aware completion inside patterns
- User symbols are scanned from the buffer (`let`, `p`, and assignments)

### Configuration

| Option                     | Default | Description                    |
|----------------------------|---------|--------------------------------|
| `completion.enabled`       | `true`  | Enable autocomplete            |
| `completion.backend`       | `"cmp"` | `"cmp"` or `"omnifunc"`        |
| `completion.source_name`   | `"tidal"` | nvim-cmp source name        |

[Back to top](#table-of-contents)

---

## 10. MIDI Controllers / /ctrl Values

Bridge hardware MIDI controllers (or software) to Tidal patterns via OSC `/ctrl` messages.

### Receiving /ctrl Values

A hardware→OSC bridge (e.g. the SuperCollider `MIDIFunc` example from the [TidalCycles playback controllers docs](https://tidalcycles.org/docs/configuration/MIDIOSC/osc/)) sends `/ctrl` messages to Tidal. If the bridge also mirrors `/ctrl` to the plugin's listener port (`osc.port`, default 5050), the values are stored and exposed to Neovim.

Your Tidal patterns read them with `cF`/`cI`/`cP`:

```haskell
d1 $ s "bass" # gain (cF 1 "amp")
```

### Neovim Integration

Commands:

- `:TidalCtrlList` — print stored values
- `:TidalCtrlClear` — clear stored values
- `:TidalCtrlSend amp 0.4` — inject a value into Tidal directly

Lua API (`require('tidal.api')`):

```lua
api.ctrl_get("amp")                       -- read one value
api.ctrl_get_all()                        -- read all values
api.ctrl_listen("amp", function(v) end)   -- subscribe to changes
api.ctrl_send("amp", 0.4)                 -- inject a value
api.ctrl_list()                           -- print received values
api.ctrl_clear()                          -- clear stored values
```

### Debugging

- `osc.ctrl_debug = true` logs every `/ctrl` at INFO level

[Back to top](#table-of-contents)

---

## 11. SuperCollider Tools

Quick access to SuperCollider's visualization tools. These send commands to sclang.

| Key    | Action                    | sclang command  |
|--------|---------------------------|-----------------|
| `<F1>` | SuperCollider meter       | `s.meter`       |
| `<F2>` | SuperCollider scope       | `s.scope`       |
| `<F3>` | SuperCollider plot tree   | `s.plotTree`    |

Available in normal, insert, and visual mode.

[Back to top](#table-of-contents)

---

## 12. TidalLooper (Live Sampling)

Integration of [TidalLooper](https://github.com/thgrund/tidal-looper) for live sampling through SuperDirt. Default **off** — enable with `boot.looper.enabled = true`.

When enabled, the boot process starts SuperDirt with an explicit `~dirt` variable and loads the looper synths from the bundled `Looper.scd` (`buffRecord`, `looper`, `olooper`, `rlooper`, `slooper`, plus `freeLoops` and `persistLoops` helpers).

### Basic Workflow

```haskell
d1 $ s "rlooper"           -- record one cycle to buffer 0 on orbit 1
d1 $ s "loop"              -- play back the loop
d1 $ s "olooper"           -- overdub onto buffer 0
d1 $ s "rlooper" # n "<0 1 2 3>"   -- record across buffers
d1 $ s "loop" # n "[0,1,2,3]"      -- play buffers
once $ s "freeLoops"               -- free all buffers
once $ s "persistLoops" # lname "loop"  -- save to disk
```

### Keymaps

| Key          | Action                                          |
|--------------|-------------------------------------------------|
| `<leader>lr` | Record loop (count prefix = orbit)              |
| `<leader>lo` | Overdub loop                                    |
| `<leader>lf` | Free buffer (count prefix = buffer)             |
| `<leader>lF` | Free all buffers                                |
| `<leader>lm` | Cycle mode: replace ↔ overdub                   |
| `<leader>lp` | Persist loops to disk                           |

### Commands

| Command                               | Description                          |
|---------------------------------------|--------------------------------------|
| `:TidalLooperRecord`                  | Record loop (count = orbit, default d1) |
| `:TidalLooperOverdub`                 | Overdub loop (count = orbit, default d1) |
| `:TidalLooperFree {n}`                | Free loop buffer n                   |
| `:TidalLooperFreeAll`                 | Free all loop buffers                |
| `:TidalLooperPersist {name}`          | Persist loops to disk                |
| `:TidalLooperMode {replace\|overdub}` | Set looper mode                      |
| `:TidalLooperInput {port}`            | Set looper input port                |

### Configuration

| Option                    | Default        | Description                 |
|---------------------------|----------------|-----------------------------|
| `boot.looper.enabled`     | `false`        | Enable TidalLooper          |
| `boot.looper.num_buffers` | `8`            | Loop buffers per bank       |
| `boot.looper.p_level`     | `0.0`          | 0.0 = replace, 1.0 = overdub|
| `boot.looper.r_level`     | `2.5`          | Recording level             |
| `boot.looper.default_input` | `0`          | Default audio input port    |
| `boot.looper.default_name` | `"loop"`      | Default sample bank name    |
| `boot.looper.persist_path` | `"~/Music/Loops/"` | Path for persisted loops |
| `boot.looper.debug_mode`  | `false`        | Looper debug logging        |

[Back to top](#table-of-contents)

---

## 13. Audio Setup (JACK)

Automatic soundcard detection and JACK (Jack Audio Connection Kit) management on boot.

On boot, the plugin parses `/proc/asound/cards` and:

- Uses a single card automatically
- Prompts via `vim.ui.select` when multiple cards exist
- Spawns `jackd -d alsa -d hw:<card>` (with up to 3 retries and `jack_wait` verification), unless `boot.sclang.soundcard` is set

### Options

| Option                    | Effect                                              |
|---------------------------|-----------------------------------------------------|
| `boot.sclang.kill_jack`   | Stop running jackd before starting a new one        |
| `boot.sclang.soundcard`   | e.g. `"hw:0"` — skip detection/prompt entirely      |
| `boot.sclang.pre_cmd`     | Shell command run before sclang starts              |

If JACK isn't available, SuperCollider manages audio itself and a warning is shown.

[Back to top](#table-of-contents)

---

## 14. Boot Files

The plugin bundles three boot files:

| File                        | Used when                  |
|-----------------------------|----------------------------|
| `bootfiles/BootTidal.hs`    | Always (Tidal GHCi)        |
| `bootfiles/BootSuperDirt.scd` | Always (SuperCollider)   |
| `bootfiles/Looper.scd`      | TidalLooper is enabled     |

### BootTidal.hs

Starts the Tidal stream on your usual SuperDirt target **plus** a second OSC target (`127.0.0.1:5050`) that feeds the visualizer, statusline, and playhead. Defines d0–d15, `hush`, `getcps/setcps`, `getbpm/setbpm`, `mute/unmute/solo/unsolo`, `once`, `first`, `asap`, `all`, `get`, `set`, `list`, `silenceOrbit`, and looper params.

### BootSuperDirt.scd

Starts SuperDirt: `SuperDirt.start;` (or loads the looper config and `Looper.scd` when the looper is enabled).

### Customization

- Set custom paths via `boot.tidal.file` / `boot.sclang.file`
- The plugin also searches the project directory for `BootTidal.hs` as a fallback
- Boot evaluation is queued until each interpreter signals readiness, then flushed

[Back to top](#table-of-contents)

---

## 15. Filetype Detection

- `*.tidal` files are set to filetype `haskell` (via `ftdetect/tidal.lua`), giving Haskell syntax highlighting
- Keymaps for sending/SC tools are installed on `haskell` (`.tidal`) and `supercollider` (`.scd`) buffers

[Back to top](#table-of-contents)
