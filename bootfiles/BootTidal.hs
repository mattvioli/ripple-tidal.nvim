import Sound.Tidal.Context
tidal <- startTidal superdirtTarget defaultConfig
let
  d1 = streamReplace tidal 1
  d2 = streamReplace tidal 2
  d3 = streamReplace tidal 3
  d4 = streamReplace tidal 4
  d5 = streamReplace tidal 5
  d6 = streamReplace tidal 6
  d7 = streamReplace tidal 7
  d8 = streamReplace tidal 8
  d9 = streamReplace tidal 9
  d10 = streamReplace tidal 10
  d11 = streamReplace tidal 11
  d12 = streamReplace tidal 12
  d13 = streamReplace tidal 13
  d14 = streamReplace tidal 14
  d15 = streamReplace tidal 15
  d16 = streamReplace tidal 16

  hush = streamHush tidal

  getcps = streamGetCPS tidal
  setcps = streamSetCPS tidal
  getbpm = streamGetBPM tidal
  setbpm = streamSetBPM tidal

  mute = streamMute tidal
  unmute = streamUnmute tidal
  solo = streamSolo tidal
  unsolo = streamUnsolo tidal
  once = streamOnce tidal
  first = streamFirst tidal
  asap = streamReplace tidal
  all = streamAll tidal
  get = streamGet tidal
  set = streamSet tidal
  list = streamList tidal
  silenceOrbit = streamSilence tidal
