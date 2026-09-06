local M = {}

M.control_params = {
  { word = "s", menu = "sound", info = "Sample bank name" },
  { word = "sound", menu = "sound", info = "Sample bank name" },
  { word = "n", menu = "note", info = "Sample index or pitch" },
  { word = "note", menu = "note", info = "Sample index or pitch" },
  { word = "gain", menu = "amp", info = "Volume (0-1)" },
  { word = "amp", menu = "amp", info = "Amplitude (0-1)" },
  { word = "pan", menu = "pan", info = "Stereo pan (0-1)" },
  { word = "speed", menu = "speed", info = "Playback speed" },
  { word = "accelerate", menu = "speed", info = "Slide playback speed" },
  { word = "begin", menu = "sample", info = "Sample start position (0-1)" },
  { word = "end", menu = "sample", info = "Sample end position (0-1)" },
  { word = "loop", menu = "sample", info = "Loop sample (0/1)" },
  { word = "cut", menu = "sample", info = "Cut group (stops other instances)" },
  { word = "sustain", menu = "env", info = "Sustain time in seconds" },
  { word = "release", menu = "env", aliases = { "rel" }, info = "Release time in seconds" },
  { word = "attack", menu = "env", aliases = { "att" }, info = "Attack time in seconds" },
  { word = "decay", menu = "env", info = "Decay time in seconds" },
  { word = "hold", menu = "env", info = "Hold time in seconds" },
  { word = "legato", menu = "env", info = "Overlap between adjacent sounds" },
  { word = "cutoff", menu = "filter", aliases = { "lpf" }, info = "Low-pass filter cutoff (Hz)" },
  { word = "resonance", menu = "filter", aliases = { "lpq" }, info = "Low-pass resonance (0-1)" },
  { word = "hcutoff", menu = "filter", aliases = { "hpf" }, info = "High-pass filter cutoff (Hz)" },
  { word = "hresonance", menu = "filter", aliases = { "hpq" }, info = "High-pass resonance (0-1)" },
  { word = "bandf", menu = "filter", aliases = { "bpf" }, info = "Band-pass center freq (Hz)" },
  { word = "bandq", menu = "filter", aliases = { "bpq" }, info = "Band-pass resonance (0-1)" },
  { word = "djf", menu = "filter", info = "DJ filter: low-pass (0-0.5), high-pass (0.5-1)" },
  { word = "vowel", menu = "filter", info = "Formant filter: a e i o u" },
  { word = "comb", menu = "filter", info = "Spectral comb filter amount" },
  { word = "hbrick", menu = "filter", info = "Spectral high-pass (0-1)" },
  { word = "lbrick", menu = "filter", info = "Spectral low-pass (0-1)" },
  { word = "room", menu = "reverb", info = "Reverb room size (0-1)" },
  { word = "size", menu = "reverb", aliases = { "sz" }, info = "Reverb depth" },
  { word = "dry", menu = "reverb", info = "Reverb dry/wet" },
  { word = "delay", menu = "delay", info = "Delay wet/dry (0-1)" },
  { word = "delaytime", menu = "delay", aliases = { "delayt" }, info = "Delay time in seconds" },
  { word = "delayfeedback", menu = "delay", aliases = { "delayfb" }, info = "Delay feedback amount" },
  { word = "lock", menu = "delay", info = "Lock delaytime to cps (0/1)" },
  { word = "crush", menu = "bits", info = "Bitcrush (1-16)" },
  { word = "coarse", menu = "bits", info = "Fake resampling (1=original)" },
  { word = "shape", menu = "dist", info = "Wave shaping (0-1)" },
  { word = "distort", menu = "dist", info = "Distortion amount" },
  { word = "triode", menu = "dist", info = "Triode distortion" },
  { word = "squiz", menu = "dist", info = "Squiz effect" },
  { word = "krush", menu = "dist", info = "Krush distortion dry/wet" },
  { word = "kcutoff", menu = "dist", info = "Krush filter cutoff" },
  { word = "fshift", menu = "pitch", info = "Frequency shift amount" },
  { word = "fshiftnote", menu = "pitch", info = "Freq shift note multiplier" },
  { word = "fshiftphase", menu = "pitch", info = "Freq shift phase" },
  { word = "octer", menu = "pitch", info = "Octave harmonics" },
  { word = "octersub", menu = "pitch", info = "Half-freq harmonics" },
  { word = "octersubsub", menu = "pitch", info = "Quarter-freq harmonics" },
  { word = "ring", menu = "pitch", info = "Ring modulation amount" },
  { word = "ringf", menu = "pitch", info = "Ring mod frequency" },
  { word = "ringdf", menu = "pitch", info = "Ring mod freq slide" },
  { word = "tremolodepth", menu = "mod", aliases = { "tremdp" }, info = "Tremolo depth" },
  { word = "tremolorate", menu = "mod", aliases = { "tremr" }, info = "Tremolo speed" },
  { word = "phaserrate", menu = "mod", aliases = { "phasr" }, info = "Phaser speed" },
  { word = "phaserdepth", menu = "mod", aliases = { "phasdp" }, info = "Phaser depth" },
  { word = "leslie", menu = "mod", info = "Leslie speaker dry/wet" },
  { word = "lrate", menu = "mod", info = "Leslie modulation rate" },
  { word = "lsize", menu = "mod", info = "Leslie cabinet size" },
  { word = "binshift", menu = "spectral", info = "Bin shifting" },
  { word = "scram", menu = "spectral", info = "Bin scrambling" },
  { word = "smear", menu = "spectral", info = "Magnitude smearing" },
  { word = "enhance", menu = "spectral", info = "Spectral enhance" },
  { word = "freeze", menu = "spectral", info = "Freeze magnitudes" },
  { word = "xsdelay", menu = "spectral", info = "Spectral delay" },
  { word = "tsdelay", menu = "spectral", info = "Spectral delay" },
  { word = "real", menu = "spectral", info = "Spectral conformer real" },
  { word = "imag", menu = "spectral", info = "Spectral conformer imag" },
  { word = "waveloss", menu = "bits", info = "Waveloss effect" },
  { word = "mode", menu = "bits", info = "Waveloss mode" },
  { word = "orbit", menu = "route", info = "SuperDirt orbit (track)" },
  { word = "cps", menu = "time", info = "Cycles per second" },
  { word = "nudge", menu = "time", info = "Push event forward/backwards in time" },
  { word = "up", menu = "pitch", info = "Change playback speed in semitones" },
  { word = "unit", menu = "sample", info = "Interprets speed as rate (r), cycles (c) or secs (s)" },
  { word = "channel", menu = "route", info = "Audio channel for Dirt" },
  { word = "velocity", menu = "midi", info = "MIDI velocity (0-127)" },
  { word = "midinote", menu = "midi", info = "MIDI note number" },
  { word = "midichan", menu = "midi", info = "MIDI channel (1-16)" },
  { word = "midicmd", menu = "midi", info = "MIDI command (play, noteOn, ctl, etc.)" },
  { word = "ctl", menu = "midi", aliases = { "cc" }, info = "MIDI continuous controller" },
  { word = "freq", menu = "freq", info = "Frequency in Hz" },
  { word = "linput", menu = "looper", info = "Looper input buffer" },
  { word = "lname", menu = "looper", info = "Looper bank name" },
  { word = "recordSource", menu = "looper", info = "Looper recording source" },
  { word = "length", menu = "time", info = "Sample length" },
  { word = "buffer", menu = "time", info = "Sample buffer" },
  { word = "instrument", menu = "synth", info = "Synth instrument name" },
  { word = "synthGroup", menu = "route", info = "Synth server group" },
  { word = "endSpeed", menu = "speed", info = "Speed at end of sample" },
}

M.pattern_functions = {
  { word = "slow", menu = "time", info = "slow n: slows pattern by n times" },
  { word = "fast", menu = "time", info = "fast n: speeds pattern by n times" },
  { word = "density", menu = "time", info = "density n: multiplies event density" },
  { word = "rev", menu = "order", info = "Reverse pattern" },
  { word = "palindrome", menu = "order", info = "Alternate forward/reverse" },
  { word = "rot", menu = "order", info = "Rotate values within pattern" },
  { word = "ribbon", menu = "order", aliases = { "rib" }, info = "Loop a slice of time" },
  { word = "cat", menu = "combine", info = "Concatenate patterns (preserve durations)" },
  { word = "slowcat", menu = "combine", info = "Alias for cat" },
  { word = "fastcat", menu = "combine", info = "Concatenate patterns (fit 1 cycle)" },
  { word = "timeCat", menu = "combine", info = "Concatenate with proportional sizes" },
  { word = "randcat", menu = "combine", info = "Randomly pick from pattern list" },
  { word = "wrandcat", menu = "combine", info = "Weighted random pick from patterns" },
  { word = "append", menu = "combine", info = "Alternate cycles between two patterns" },
  { word = "slowAppend", menu = "combine", info = "Alias for append" },
  { word = "fastAppend", menu = "combine", info = "Alternate squashed into 1 cycle" },
  { word = "stack", menu = "combine", info = "Layer patterns together" },
  { word = "wedge", menu = "combine", info = "Squash two patterns into 1 cycle by ratio" },
  { word = "brak", menu = "combine", info = "Breakbeat effect" },
  { word = "degrade", menu = "random", info = "Remove 50% of events randomly" },
  { word = "degradeBy", menu = "random", info = "Remove events by probability" },
  { word = "unDegradeBy", menu = "random", info = "Keep events by probability" },
  { word = "sometimes", menu = "cond", info = "Apply function sometimes" },
  { word = "often", menu = "cond", info = "Apply function often" },
  { word = "rarely", menu = "cond", info = "Apply function rarely" },
  { word = "almostNever", menu = "cond", info = "Apply function almost never" },
  { word = "almostAlways", menu = "cond", info = "Apply function almost always" },
  { word = "never", menu = "cond", info = "Never apply function" },
  { word = "every", menu = "cond", info = "Apply function every n cycles" },
  { word = "whenmod", menu = "cond", info = "Apply when cycle mod n == m" },
  { word = "chunk", menu = "part", info = "Apply function to parts in sequence" },
  { word = "chunk'", menu = "part", info = "Apply function to parts in reverse" },
  { word = "bite", menu = "part", info = "Slice pattern into n bits, reorder" },
  { word = "slice", menu = "part", info = "Slice sample into n parts" },
  { word = "striate", menu = "part", info = "Granulate sample into n grains" },
  { word = "chop", menu = "part", info = "Chop sample into n pieces" },
  { word = "shuffle", menu = "random", info = "Random permutation of n parts" },
  { word = "scramble", menu = "random", info = "Random selection of n parts" },
  { word = "spread", menu = "higher", info = "Spread function across values" },
  { word = "spreadf", menu = "higher", info = "Shorthand for spread ($)" },
  { word = "fastspread", menu = "higher", info = "Spread squashed into 1 cycle" },
  { word = "spreadChoose", menu = "higher", aliases = { "spreadr" }, info = "Random spread" },
  { word = "jux", menu = "stereo", info = "Apply function to opposite stereo channels" },
  { word = "juxBy", menu = "stereo", info = "Jux with blend amount" },
  { word = "iter", menu = "order", info = "Shift pattern start each cycle" },
  { word = "iter'", menu = "order", info = "Iter in reverse direction" },
  { word = "range", menu = "value", info = "Scale 0-1 pattern to new range" },
  { word = "rangex", menu = "value", info = "Exponential range scaling" },
  { word = "quantise", menu = "value", info = "Round values to nearest fraction" },
  { word = "ply", menu = "repeat", info = "Repeat each event n times" },
  { word = "plyWith", menu = "repeat", info = "Ply with function applied" },
  { word = "stutter", menu = "repeat", info = "Repeat events n times with time offset" },
  { word = "echo", menu = "repeat", info = "Stutter with 2 repeats" },
  { word = "triple", menu = "repeat", info = "Stutter with 3 repeats" },
  { word = "quad", menu = "repeat", info = "Stutter with 4 repeats" },
  { word = "double", menu = "repeat", info = "Alias for echo" },
  { word = "stripe", menu = "repeat", info = "Repeat at random speeds over n cycles" },
  { word = "slowstripe", menu = "repeat", info = "Stripe slowed by n" },
  { word = "trunc", menu = "trim", info = "Play only first fraction of pattern" },
  { word = "linger", menu = "trim", info = "Repeat first fraction to fill cycle" },
  { word = "loopFirst", menu = "trim", info = "Loop only first cycle" },
  { word = "timeLoop", menu = "trim", info = "Apply modulo t to cycle sequence" },
  { word = "run", menu = "gen", info = "Generate 0 to n-1 sequence" },
  { word = "scan", menu = "gen", info = "Add one each cycle until n" },
  { word = "step", menu = "gen", info = "Step sequencer from string" },
  { word = "step'", menu = "gen", info = "Step sequencer from list" },
  { word = "listToPat", menu = "gen", info = "List to pattern (all in 1 cycle)" },
  { word = "fastFromList", menu = "gen", info = "Alias for listToPat" },
  { word = "fromList", menu = "gen", info = "List to pattern (1 per cycle)" },
  { word = "fromMaybes", menu = "gen", info = "List with Nothing as rests" },
  { word = "flatpat", menu = "gen", info = "Flatten pattern of lists" },
  { word = "lindenmayer", menu = "gen", info = "Generate L-system string" },
  { word = "distrib", menu = "gen", info = "Euclidean distribution variant" },
  { word = "snowball", menu = "higher", info = "Recursively apply+combine" },
  { word = "soak", menu = "higher", info = "Repeatedly apply function" },
  { word = "spaceOut", menu = "repeat", info = "Repeat at varied durations" },
  { word = "permstep", menu = "gen", info = "Permutations of list" },
  { word = "const", menu = "higher", info = "Replace pattern with another" },
  { word = "trigger", menu = "time", info = "Align pattern to evaluation time" },
  { word = "qtrigger", menu = "time", aliases = { "qt" }, info = "Quantised trigger (next cycle)" },
  { word = "mtrigger", menu = "time", aliases = { "mt" }, info = "Mod trigger (divisible cycles)" },
  { word = "triggerWith", menu = "time", info = "Trigger with custom time mapping" },
  { word = "hurry", menu = "time", info = "Speed up and raise pitch by n" },
  { word = "zoom", menu = "trim", info = "Play only a time span of the pattern" },
  { word = "within", menu = "part", info = "Apply function to a time span of the pattern" },
  { word = "loopAt", menu = "sample", info = "Speed sample to fit given number of cycles" },
  { word = "gap", menu = "part", info = "Granulate, but every other grain is silent" },
  { word = "smash", menu = "part", info = "Cut into bits, play at varied speeds" },
  { word = "stut", menu = "repeat", info = "Echo: depth, feedback, time" },
  { word = "stut'", menu = "repeat", info = "Echo with a function applied per repeat" },
  { word = "off", menu = "repeat", info = "Apply function to a delayed copy" },
  { word = "spin", menu = "stereo", info = "Layer copies panned across the stereo field" },
  { word = "jux'", menu = "stereo", info = "Jux, keeping the affected layer centered" },
  { word = "jux4", menu = "stereo", info = "Jux across four quadrants" },
  { word = "superimpose", menu = "combine", info = "Play a transformed copy at the same time" },
  { word = "weave", menu = "combine", info = "Weave parameter patterns together" },
  { word = "weave'", menu = "combine", info = "Weave with function amounts" },
  { word = "interlace", menu = "combine", info = "Interleave two patterns per event" },
  { word = "fit", menu = "gen", info = "Select values from a list by integer pattern" },
  { word = "fit'", menu = "gen", info = "Select slices of one pattern by another" },
  { word = "toScale", menu = "gen", info = "Map note pattern into a scale" },
  { word = "toScale'", menu = "gen", info = "toScale spanning multiple octaves" },
  { word = "seqP", menu = "gen", info = "Sequence of patterns with start/end times" },
  { word = "seqPLoop", menu = "gen", info = "seqP that loops at the end" },
  { word = "swingBy", menu = "time", info = "Swing: delay second half by amount and n" },
  { word = "mask", menu = "cond", info = "Keep events that align with a bool pattern" },
  { word = "ifp", menu = "cond", info = "Apply a or b depending on a cycle test" },
  { word = "someCyclesBy", menu = "cond", info = "Apply function on some cycles by probability" },
  { word = "foldEvery", menu = "cond", info = "Chain several every transformations" },
  { word = "mtof", menu = "freq", info = "MIDI note number to frequency" },
  { word = "anticipate", menu = "transition", info = "Build-up before switching patterns" },
  { word = "clutch", menu = "transition", info = "Degrade current, undegrade next pattern" },
  { word = "jump", menu = "transition", info = "Immediate transition" },
  { word = "jumpIn", menu = "transition", info = "Jump transition after n cycles" },
  { word = "jumpIn'", menu = "transition", info = "Jump at the next cycle boundary" },
  { word = "jumpMod", menu = "transition", info = "Jump when cycle mod n is zero" },
  { word = "wash", menu = "transition", info = "Wash away current pattern into next" },
  { word = "superwash", menu = "transition", info = "Apply a function while washing away" },
  { word = "wait", menu = "transition", info = "Stop then play the new pattern" },
  { word = "xfade", menu = "transition", info = "Crossfade over two cycles" },
  { word = "xfadeIn", menu = "transition", info = "Crossfade over n cycles" },
  { word = "mortal", menu = "transition", info = "Degrade new pattern into silence" },
  { word = "histpan", menu = "transition", info = "Pan last n pattern versions across field" },
}

M.orbit_aliases = {}
for i = 0, 16 do
  table.insert(M.orbit_aliases, { word = "d" .. i, menu = "orbit", info = "Orbit " .. i .. " pattern" })
end

M.top_level = {
  { word = "hush", menu = "cmd", info = "Stop all patterns" },
  { word = "panic", menu = "cmd", info = "Hush + kill all synths" },
  { word = "silence", menu = "cmd", info = "Silence a specific pattern" },
  { word = "silenceOrbit", menu = "cmd", info = "Silence an orbit" },
  { word = "once", menu = "cmd", info = "Play pattern once" },
  { word = "first", menu = "cmd", info = "Play the first pattern only" },
  { word = "asap", menu = "cmd", info = "Fork a pattern immediately" },
  { word = "all", menu = "cmd", info = "Apply a function to all patterns" },
  { word = "get", menu = "cmd", info = "Get a running pattern" },
  { word = "set", menu = "cmd", info = "Set a pattern by name" },
  { word = "list", menu = "cmd", info = "List running patterns" },
  { word = "mute", menu = "cmd", info = "Mute a pattern" },
  { word = "unmute", menu = "cmd", info = "Unmute a pattern" },
  { word = "solo", menu = "cmd", info = "Solo a pattern" },
  { word = "unsolo", menu = "cmd", info = "Unsolo a pattern" },
  { word = "setcps", menu = "tempo", info = "Set cycles per second" },
  { word = "getcps", menu = "tempo", info = "Get cycles per second" },
  { word = "setbpm", menu = "tempo", info = "Set beats per minute" },
  { word = "getbpm", menu = "tempo", info = "Get beats per minute" },
  { word = "resetCycles", menu = "tempo", info = "Reset cycle count to 0" },
  { word = "setCycle", menu = "tempo", info = "Set cycle to given number" },
  { word = "drawLine", menu = "vis", info = "Visualize pattern as text" },
}

M.oscillators = {
  { word = "sine", menu = "osc", info = "Sine wave 0-1" },
  { word = "cosine", menu = "osc", info = "Cosine wave 0-1" },
  { word = "tri", menu = "osc", info = "Triangle wave 0-1" },
  { word = "saw", menu = "osc", info = "Saw wave 0-1" },
  { word = "square", menu = "osc", info = "Square wave 0-1" },
  { word = "rand", menu = "osc", info = "Random value 0-1" },
  { word = "irand", menu = "osc", info = "Random integer" },
  { word = "perlin", menu = "osc", info = "Perlin noise" },
}

M.mini_notation_ops = {
  { word = "~", menu = "mini", info = "Rest" },
  { word = "*", menu = "mini", info = "Repeat (e.g. bd*2)" },
  { word = "/", menu = "mini", info = "Slow down (e.g. bd/2)" },
  { word = ":", menu = "mini", info = "Sample index (e.g. bd:3)" },
  { word = "!", menu = "mini", info = "Replicate (e.g. bd!3)" },
  { word = "_", menu = "mini", info = "Elongate (tie)" },
  { word = "@", menu = "mini", info = "Elongate by n" },
  { word = "?", menu = "mini", info = "Randomly remove (e.g. bd?)" },
  { word = "[]", menu = "mini", info = "Pattern grouping (subdivision)" },
  { word = "<>", menu = "mini", info = "Alternate between patterns" },
  { word = "{}", menu = "mini", info = "Polymetric sequences" },
  { word = ",", menu = "mini", info = "Superposition (inside [])" },
  { word = "|", menu = "mini", info = "Random choice (inside [])" },
  { word = ".", menu = "mini", info = "Pattern grouping shorthand" },
  { word = "%", menu = "mini", info = "Ratio shorthand or subdiv" },
  { word = "()", menu = "mini", info = "Euclidean sequence (n,k)" },
}

function M.get_all_params()
  local result = {}
  for _, p in ipairs(M.control_params) do
    table.insert(result, p.word)
    if p.aliases then
      for _, a in ipairs(p.aliases) do
        table.insert(result, a)
      end
    end
  end
  return result
end

function M.get_all_functions()
  local result = {}
  for _, f in ipairs(M.pattern_functions) do
    table.insert(result, f.word)
    if f.aliases then
      for _, a in ipairs(f.aliases) do
        table.insert(result, a)
      end
    end
  end
  return result
end

function M.get_all_keywords()
  local result = {}
  local function add(list)
    for _, item in ipairs(list) do
      result[item.word] = item
      if item.aliases then
        for _, a in ipairs(item.aliases) do
          result[a] = vim.tbl_deep_extend("force", {}, item)
          result[a].alias_of = item.word
        end
      end
    end
  end
  add(M.control_params)
  add(M.pattern_functions)
  add(M.orbit_aliases)
  add(M.top_level)
  add(M.oscillators)
  return result
end

return M
