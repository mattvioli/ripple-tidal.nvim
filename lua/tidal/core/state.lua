local state = {
  launched = false,
  launching = false,
  soundcard = nil,
  ghci = nil,
  ghci_win = nil,
  ghci_buf = nil,
  sclang = nil,
  sclang_win = nil,
  sclang_buf = nil,
  osc = nil,
  osc_running = false,
  current_cps = nil,
  current_cycle = nil,
  playhead = nil,
}

return state
