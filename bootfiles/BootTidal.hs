: {
import Sound.Tidal.Context
}

tidal <- startTidal superdirtTarget defaultConfig

{
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

  getcps = streamGetCps tidal
  setcps = streamSetCps tidal
  getbpm = streamGetBPM tidal
  setbpm = streamSetBPM tidal

  -- transitions
  anticipate = streamAnticipate tidal
  die = streamDie tidal
  interpolate = streamInterpolate tidal
  jump = streamJump tidal
  jumpIn = streamJumpIn tidal
  jumpIn' = streamJumpIn' tidal
  jumpMod = streamJumpMod tidal
  jumpMod' = streamJumpMod' tidal
  mute = streamMute tidal
  unmute = streamUnmute tidal
  solo = streamSolo tidal
  unsolo = streamUnsolo tidal
  once = once tidal
  first = streamFirst tidal
  asap = streamReplace tidal
  qtrigger = streamQtell tidal
  trigger = streamTell tidal
  cps = streamGetCps tidal
  bpm = streamGetBPM tidal
  wait = streamWait tidal
  waitT = streamWaitT tidal
in return()
}
: }
