# tidal-ripple.nvim Tutorial

A hands-on guide to live-coding music with TidalCycles in Neovim.

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Sending Code to TidalCycles](#2-sending-code-to-tidalcycles)
3. [Managing Patterns](#3-managing-patterns)
4. [Visual Feedback](#4-visual-feedback)
5. [OSC Playback Control](#5-osc-playback-control)
6. [The Beat Grid Visualizer](#6-the-beat-grid-visualizer)
7. [Statusline](#7-statusline)
8. [Tap Tempo](#8-tap-tempo)
9. [Sample Browser](#9-sample-browser)
10. [Autocomplete](#10-autocomplete)
11. [MIDI Controllers & /ctrl Values](#11-midi-controllers--ctrl-values)
12. [SuperCollider Tools](#12-supercollider-tools)
13. [TidalLooper (Live Sampling)](#13-tidallooper-live-sampling)
14. [Customization](#14-customization)

---

## 1. Quick Start

### Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "mattvioli/tidal-ripple.nvim",
  opts = {},
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "haskell", "supercollider" } },
  },
}
```

### Your First Pattern

Open a `.tidal` file and write a pattern:

```haskell
d1 $ s "bd sn"
```

Place your cursor anywhere on that line and press `<S-CR>` (Shift+Enter). The plugin:

1. Auto-launches GHCi and SuperCollider (if `auto_launch = true`, the default)
2. Sends the line to GHCi
3. Flashes the line briefly to confirm the send
4. Places a `▶` playhead marker next to the line

That's it — you should hear a kick and snare pattern. The playhead marker will flash in sync with the audio.

### Key Bindings Reference

| Key             | Mode       | Action                                  |
|-----------------|------------|-----------------------------------------|
| `<S-CR>`        | i, n       | Send current line                       |
| `<S-CR>`        | x          | Send visual selection                   |
| `<M-CR>`        | i, n, x    | Send contiguous block                   |
| `<leader><CR>`  | n          | Send tree-sitter node under cursor      |
| `<leader>d`     | n          | Silence an orbit (e.g. `2<leader>d`)    |
| `<leader><Esc>` | n          | Hush all patterns                       |

---

## 2. Sending Code to TidalCycles

tidal-ripple.nvim offers several ways to send code, depending on what you want to evaluate.

### Send a Single Line

The most common operation. Put your cursor on a line and press `<S-CR>`:

```haskell
d1 $ s "bd sn" # speed 2
```

This works in both insert and normal mode.

### Send a Visual Selection

Select text in visual mode (including `Ctrl-V` block selection) and press `<S-CR>`. The selected text is sent as a single evaluation:

```haskell
-- select these two lines and press <S-CR>
d1 $ s "bd sn"
  # shape "triangle"
```

### Send a Block

To send a multi-line expression without visually selecting it, use `<M-CR>` (Alt+Enter). The plugin finds the contiguous block of non-empty lines around your cursor and sends them all:

```haskell
d1 $ s "bd sn"
  # speed "2 4"
  # room 0.3
  # orbit 1
```

Place your cursor on any of these lines and press `<M-CR>` — all four lines are sent together.

### Send a Tree-Sitter Node

For more precise control, `<leader><CR>` sends the tree-sitter node under your cursor. This is useful when you have nested expressions and want to evaluate just one part.

### Silence and Hush

- **Silence one orbit**: `2<leader>d` sends `d2 silence`. The count prefix selects the orbit (defaults to d1 without a count).
- **Hush everything**: `<leader><Esc>` sends `hush`, stopping all patterns at once.

---

## 3. Managing Patterns

### Orbit Assignment

TidalCycles uses orbits (d0 through d15) to route patterns. You assign patterns to orbits in your `.tidal` file:

```haskell
d1 $ s "bd sn"
d2 $ s "hh*8"
d3 $ s "cp" # orbit 3
```

Use the orbit number in `<leader>d` to silence a specific orbit. For example, `2<leader>d` silences d2.

### Silence by Name

You can also silence patterns by name using the commands:

```
:TidalSilence 1       " silence d1
:TidalSilence 3       " silence d3
:TidalHush            " silence everything
```

### Hush via OSC

`<leader>h` sends a hush command directly over OSC (port 6010) instead of through GHCi. This is useful when GHCi is busy or you want an immediate stop.

---

## 4. Visual Feedback

tidal-ripple.nvim provides several layers of visual feedback to help you track what's happening.

### Flash-on-Send

When you send code, the lines flash briefly (default 150ms, using the `IncSearch` highlight group). This confirms the send visually.

### Playhead Markers

A `▶` sign appears in the sign column next to every line you've sent. These markers flash in sync with the actual audio timing, driven by OSC `/dirt/play` feedback from TidalCycles.

The flash duration is derived from the event's `delta` value — fast patterns produce quick flashes, slow patterns produce longer ones.

### Event Highlighting

Lines that are actively producing sound flash in sync with the audio. This is separate from the playhead — it highlights the buffer line itself. The base flash duration defaults to 400ms.

Both features require the OSC listener to be running (`:TidalOSCToggle` / `<leader>o`).

---

## 5. OSC Playback Control

tidal-ripple.nvim communicates with TidalCycles over OSC, giving you hardware-level control without going through GHCi.

### Mute and Unmute

```
<leader>m       " mute all patterns
<leader>u       " unmute all patterns
2<leader>m      " mute orbit 2 only
2<leader>u      " unmute orbit 2 only
```

Or via commands:

```
:TidalMute        " mute all
:TidalMute 3      " mute orbit 3
:TidalMute "bass" " mute the pattern named "bass"
:TidalUnmute      " unmute all
```

### Solo and Unsolo

Soloing mutes all other orbits and plays only the selected one:

```
<leader>s        " solo the current orbit
2<leader>s       " solo orbit 2
<leader>S        " unsolo (restore previous state)
```

### Hush via OSC

```
<leader>h        " immediate hush over OSC
```

This sends `/hush` directly to Tidal's OSC input on port 6010, bypassing GHCi entirely.

---

## 6. The Beat Grid Visualizer

A floating window that shows a real-time beat grid for each active orbit.

### Opening the Visualizer

```
<leader>v                " toggle the visualizer
:TidalVisualizerToggle  " same thing
```

Close it with `q` or `<Esc>`.

### What It Shows

- A **header** with live CPS (cycles per second) and cycle position
- **Per-orbit rows** with colored markers that advance across the grid
- Markers are colored by sound (each sound gets a color from the palette)
- Animation is driven by OSC timing, so it stays in sync with the audio

### Configuring It

```lua
{
  visualizer = {
    width = 60,             -- window width
    height = 12,            -- window height
    border = "single",      -- window border style
    refresh_interval_ms = 33, -- redraw interval (~30fps)
    grid = {
      divisions = 4,        -- beats per cycle
      total_cycles = 1,     -- how many cycles to show
      chars_per_beat = 8,   -- characters per beat on the grid
    },
    palette = {             -- 8 colors for orbit markers
      "#FF6B6B", "#51CF66", "#FFD43B", "#339AF0",
      "#CC5DE8", "#20C997", "#F06595", "#FF922B",
    },
    max_orbits = 8,         -- max orbits displayed
    max_events_per_orbit = 4,
  },
}
```

---

## 7. Statusline

A live component that shows CPS, cycle position, BPM, and time signature.

### Setup

For **lualine** users:

```lua
require('lualine').setup {
  sections = {
    lualine_x = {
      { function() return require('tidal.core.statusline').get_status() end },
    },
  },
}
```

For the **built-in statusline**:

```lua
vim.o.statusline = "%!v:lua.require('tidal.core.statusline').get_status()"
```

### Customizing the Format

The `statusline.format` option supports these placeholders:

| Placeholder | Description         |
|-------------|---------------------|
| `{cps}`     | Cycles per second   |
| `{cycle}`   | Current cycle       |
| `{bpm}`     | Beats per minute    |
| `{timesig}` | Time signature      |

Default format:

```lua
statusline = {
  format = "♩ {cps} CPS | c.{cycle}",
}
```

A more detailed example:

```lua
statusline = {
  format = "♩ {cps} CPS | {bpm} BPM | {timesig} | c.{cycle}",
}
```

---

## 8. Tap Tempo

Determine BPM by tapping along with the music.

### Using Tap Tempo

1. Press `<leader>t` (or `:TidalTapTempo`) to open the tap tempo popup
2. In the target `.tidal` buffer, press `n` to tap downbeats
3. Press `m` to tap sub-beats (helps infer the time signature)
4. After a few taps (`taptempo.min_taps`, default 2), the BPM is sent as `setcps`
5. The popup displays big ASCII-art BPM and time signature digits

### Time Signature Inference

The plugin infers the time signature from the ratio of downbeats to sub-beats:

- Tap `n` on each beat and `m` on each subdivision
- For example, in 4/4: `n m m m n m m m n m m m n m m m`
- In 3/4: `n m m n m m n m m n m m`
- In 6/8: tap `m` on each eighth note

### Exiting Tap Mode

- Tap a beat that's more than 3× the median interval to exit automatically
- Press `<leader>t` again to toggle off
- Use `:TidalTapTempoReset` to clear history and start fresh

### Configuration

```lua
taptempo = {
  min_taps = 2,             -- taps before BPM is sent
  max_taps = 16,            -- max taps kept in history
  outlier_threshold = 0.3,  -- discard intervals 30%+ from median
  exit_factor = 3.0,        -- tap 3x median to exit
}
```

---

## 9. Sample Browser

Browse all 218 Dirt-Samples banks shipped with SuperDirt.

### Opening the Browser

```
<leader>a                  " toggle the sample browser
:TidalSampleBrowser        " same thing
```

### Navigation

| Key          | Action                                    |
|--------------|-------------------------------------------|
| `<CR>`       | Drill into the selected bank's file list  |
| `<leader>i`  | Same as `<CR>`                            |
| `<BS>`       | Go back one level                         |
| `q` / `<Esc>`| Close the browser                         |

### Investigating from a .tidal Buffer

Place your cursor on a sample name in your code and press `<leader>i` (or `:TidalSampleInvestigate`). The browser opens with that bank's details.

For example, if your cursor is on `"bd"` in:

```haskell
d1 $ s "bd sn"
```

Pressing `<leader>i` will show you the `bd` bank and its available samples.

### Customizing Descriptions

Override or blank the bundled descriptions by creating `~/.config/nvim/tidal-ripple/sample_descriptions.lua`:

```lua
return {
  bd = "my favourite kick drum",
  hh = "",          -- blank the description
  cp = "clap sound",
}
```

---

## 10. Autocomplete

Context-aware completion for Tidal patterns, enabled by default.

### What It Completes

The completions change based on your cursor context:

| Context        | Example Input   | Completions                        |
|----------------|-----------------|------------------------------------|
| Sample names   | `s"bd<cursor>"` | `bd`, `cp`, `808`, `jvbass`, ...  |
| Sample indices | `n"bd:3<cursor>"` | `0`, `1`, `2`, ..., `a`, `b`, ...  |
| Control params | `# <cursor>`    | `cps`, `pan`, `vowel`, `gain`, ... |
| Pattern funcs  | `d1 $ <cursor>` | `slow`, `rev`, `every`, `chop`, ...|
| Keywords       | `<cursor>`      | `hush`, `panic`, `setcps`, `d0`..`d15` |
| Your symbols   | `<cursor>`      | `let` bindings, `p` definitions, assignments |

### Backends

**nvim-cmp** (default): Registers a source named `tidal`. If you configure nvim-cmp sources manually, add `{ name = "tidal" }`.

**omnifunc**: Used when nvim-cmp isn't installed. Set `completion.backend = "omnifunc"` in the config. Triggers automatically via a debounced popup or manually with `<C-x><C-o>`.

### Best Results

Install `nvim-treesitter` with the `haskell` parser for the best context detection. Without it, a regex-based parser is used (a one-time notice is shown).

---

## 11. MIDI Controllers & /ctrl Values

tidal-ripple.nvim can receive and send `/ctrl` OSC messages, bridging MIDI controllers to Tidal patterns.

### Sending /ctrl Values

Send a value from Neovim directly to Tidal:

```
:TidalCtrlSend amp 0.4
:TidalCtrlSend cutoff 800
```

Or via the Lua API:

```lua
require('tidal.api').ctrl_send("amp", 0.4)
```

### Reading /ctrl Values

If a hardware MIDI controller sends `/ctrl` messages to Tidal (via an OSC bridge), and the bridge mirrors them to port 5050, the plugin stores them:

```
:TidalCtrlList     " print all stored values
:TidalCtrlClear    " clear stored values
```

Or via the Lua API:

```lua
local api = require('tidal.api')
api.ctrl_get("amp")           -- read one value
api.ctrl_get_all()            -- read all values
api.ctrl_listen("amp", function(val)  -- subscribe to changes
  print("amp changed to:", val)
end)
```

### Using /ctrl in Tidal Patterns

```haskell
d1 $ s "bass" # gain (cF 1 "amp")
d1 $ s "hh" # cutoff (cI 1 "cutoff")
```

### Debugging

Enable logging to see every incoming `/ctrl` message:

```lua
osc = {
  ctrl_debug = true,  -- log at INFO level
}
```

---

## 12. SuperCollider Tools

Quick access to SuperCollider's visualization tools from Neovim.

| Key   | Action                          |
|-------|---------------------------------|
| `<F1>`| Open SuperCollider meter        |
| `<F2>`| Open SuperCollider scope        |
| `<F3>`| Open SuperCollider plot tree    |

These send `s.meter`, `s.scope`, and `s.plotTree` to sclang respectively.

---

## 13. TidalLooper (Live Sampling)

The plugin integrates [TidalLooper](https://github.com/thgrund/tidal-looper) for live sampling through SuperDirt.

### Enabling the Looper

```lua
{
  boot = {
    looper = {
      enabled = true,
      num_buffers = 8,       -- loop buffers per bank
      p_level = 0.0,         -- 0.0 = replace, 1.0 = overdub
      r_level = 2.5,         -- recording level
      default_input = 0,     -- audio input port
      default_name = "loop", -- sample bank name
      persist_path = "~/Music/Loops/",
    },
  },
}
```

### Basic Looper Workflow

1. **Record** a loop:

```haskell
d1 $ s "rlooper"    -- record one cycle to buffer 0 on orbit 1
```

2. **Play it back**:

```haskell
d1 $ s "loop"       -- play the recorded loop
```

3. **Overdub** on top:

```haskell
d1 $ s "olooper"    -- overdub onto buffer 0
```

4. **Cycle through buffers**:

```haskell
d1 $ s "rlooper" # n "<0 1 2 3>"   -- record to buffers 0-3
d1 $ s "loop" # n "[0,1,2,3]"      -- play all buffers
```

5. **Free buffers** when done:

```haskell
once $ s "freeLoops"               -- free all buffers
```

6. **Persist to disk** to save your loops:

```haskell
once $ s "persistLoops" # lname "myset"
```

### Looper Keymaps

| Key          | Action                                          |
|--------------|-------------------------------------------------|
| `<leader>lr` | Record loop (count prefix = orbit, e.g. `2<leader>lr`) |
| `<leader>lo` | Overdub loop                                    |
| `<leader>lf` | Free buffer (count prefix = buffer number)      |
| `<leader>lF` | Free all buffers                                |
| `<leader>lm` | Cycle mode: replace ↔ overdub                   |
| `<leader>lp` | Persist loops to disk                           |

### Looper Commands

```
:TidalLooperRecord            " record on d1 (use count for orbit)
:TidalLooperOverdub           " overdub on d1
:TidalLooperFree 3            " free buffer 3
:TidalLooperFreeAll           " free all buffers
:TidalLooperPersist myloops   " persist with name "myloops"
:TidalLooperMode overdub      " set mode to overdub
:TidalLooperInput 2           " set input port to 2
```

---

## 14. Customization

### Disabling Auto-Launch

If you prefer to boot manually:

```lua
{ auto_launch = false }
```

Then use `:TidalLaunch` when you're ready.

### Custom Boot Files

```lua
{
  boot = {
    tidal = {
      file = "/path/to/my/BootTidal.hs",
    },
    sclang = {
      file = "/path/to/my/BootSuperDirt.scd",
    },
  },
}
```

The plugin also searches the project directory for `BootTidal.hs` as a fallback.

### REPL Split Direction

```lua
boot = {
  split = "v",  -- vertical split (default is "h" for horizontal)
}
```

### Soundcard Configuration

If you have multiple audio devices or want to skip detection:

```lua
boot = {
  sclang = {
    soundcard = "hw:0",       -- skip detection, use this card directly
    kill_jack = true,         -- stop existing jackd before starting
    pre_cmd = "export SRT_DEVICE=hw:1",  -- command run before sclang
  },
}
```

### Disabling Features

Turn off any feature you don't need:

```lua
{
  event_highlight = { enabled = false },  -- no audio-synced line flashing
  playhead = { enabled = false },         -- no ▶ markers
  statusline = { enabled = false },       -- no statusline component
  completion = { enabled = false },       -- no autocomplete
  osc = { enabled = false },             -- no OSC listener
}
```

### Custom Highlight Groups

Override the visual appearance of any highlight:

```lua
{
  selection_highlight = {
    highlight = { fg = "#FF0000", bold = true },
    timeout = 200,
  },
  playhead = {
    highlight = { link = "DiagnosticSignInfo" },
  },
  event_highlight = {
    highlight = { bg = "#333333" },
    fade_ms = 300,
  },
}
```

### Rebinding Keymaps

Change or remove any keymap:

```lua
{
  mappings = {
    send_line = { mode = { "i", "n" }, key = "<CR>" },  -- remap send to Enter
    send_hush = nil,  -- remove the hush mapping entirely
  },
}
```

### Oscillator / Visualizer Colors

Customize the visualizer palette:

```lua
{
  visualizer = {
    palette = {
      "#FF0000", "#00FF00", "#0000FF", "#FFFF00",
      "#FF00FF", "#00FFFF", "#FFFFFF", "#888888",
    },
  },
}
```

### Advanced OSC Configuration

```lua
{
  osc = {
    port = 5050,        -- listener port (must match boot.tidal.osc_target.port)
    tidal_port = 6010,  -- Tidal's OSC control input
    enabled = true,
    debug = true,       -- log every /dirt/play message (useful for debugging)
  },
}
```
