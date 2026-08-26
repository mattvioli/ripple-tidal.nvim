local state = require("tidal.core.state")

local M = {}

M.tidal = {}

function M.tidal.send(text)
  if not state.ghci then
    return
  end
  state.ghci:send(text)
end

function M.tidal.send_line(text)
  if not state.ghci then
    return
  end
  state.ghci:send_line(text)
end

function M.tidal.send_multiline(lines)
  if not state.ghci then
    return
  end
  state.ghci:send_multiline(lines)
end

M.sclang = {}

function M.sclang.send(text)
  if not state.sclang then
    return
  end
  state.sclang:send(text)
end

function M.sclang.send_line(text)
  if not state.sclang then
    return
  end
  state.sclang:send_line(text)
end

function M.sclang.send_multiline(lines)
  if not state.sclang then
    return
  end
  state.sclang:send_multiline(lines)
end

return M
