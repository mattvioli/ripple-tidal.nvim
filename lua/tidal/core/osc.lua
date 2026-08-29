local config = require("tidal.config")
local state = require("tidal.core.state")
local notify = require("tidal.util.notify")

local M = {}

function M.decode(data)
  local pos = 1

  local function read_string()
    local start = pos
    while pos <= #data and data:byte(pos) ~= 0 do
      pos = pos + 1
    end
    local str = data:sub(start, pos - 1)
    pos = pos + 1
    pos = pos + ((4 - (pos - start - 1) % 4 - 1) % 4)
    return str
  end

  local address = read_string()
  local type_tags = read_string()

  if type_tags:byte(1) ~= 44 then
    return nil
  end

  local args = {}
  for i = 2, #type_tags do
    local tag = type_tags:sub(i, i)
    if tag == "f" then
      local val = string.unpack(">f", data:sub(pos, pos + 3))
      table.insert(args, val)
      pos = pos + 4
    elseif tag == "i" then
      local val = string.unpack(">i4", data:sub(pos, pos + 3))
      table.insert(args, val)
      pos = pos + 4
    elseif tag == "s" then
      local str = read_string()
      table.insert(args, str)
    elseif tag == "d" then
      local val = string.unpack(">d", data:sub(pos, pos + 7))
      table.insert(args, val)
      pos = pos + 8
    elseif tag == "T" then
      table.insert(args, true)
    elseif tag == "F" then
      table.insert(args, false)
    elseif tag == "N" then
      table.insert(args, nil)
    elseif tag == "I" then
      table.insert(args, math.huge)
    end
  end

  return { address = address, args = args }
end

local function parse_dirt_play(msg)
  local args = msg.args
  if #args < 5 then
    return nil
  end

  local sound = args[1]
  local cycle = args[2]
  local cps = args[3]
  local orbit = args[4] + 1
  local delta = args[5]

  return {
    sound = sound,
    cycle = cycle,
    cps = cps,
    orbit = orbit,
    delta = delta,
  }
end

local function on_message(data)
  local msg = M.decode(data)
  if not msg then
    return
  end

  if msg.address ~= "/dirt/play" then
    return
  end

  local parsed = parse_dirt_play(msg)
  if not parsed then
    return
  end

  state.current_cps = parsed.cps
  state.current_cycle = parsed.cycle

  local playhead = require("tidal.core.playhead")
  playhead.on_cycle(parsed)
end

local function on_read(err, data)
  if err then
    return
  end
  if not data then
    return
  end

  local pos = 1
  while pos <= #data do
    local bundle_header = data:sub(pos, pos + 7)
    if bundle_header == "#bundle" then
      pos = pos + 8
      pos = pos + 8
      while pos <= #data do
        if pos + 3 > #data then
          break
        end
        local _, elem_len = string.unpack(">I4", data:sub(pos, pos + 3))
        pos = pos + 4
        if pos + elem_len > #data + 1 then
          break
        end
        local elem = data:sub(pos, pos + elem_len - 1)
        on_message(elem)
        pos = pos + elem_len
      end
    else
      local remaining = data:sub(pos)
      on_message(remaining)
      break
    end
  end
end

function M.start()
  if state.osc then
    return
  end

  local port = config.options.osc.port
  local udp = vim.uv.new_udp()
  if not udp then
    notify.error("OSC: failed to create UDP socket")
    return
  end

  udp:bind("127.0.0.1", port)
  udp:recv_start(on_read)

  state.osc = udp
  state.osc_running = true

  notify.info(string.format("OSC listener started on port %d", port))
end

function M.stop()
  if not state.osc then
    return
  end

  state.osc:close()
  state.osc = nil
  state.osc_running = false
  state.current_cps = nil
  state.current_cycle = nil

  notify.info("OSC listener stopped")
end

function M.restart()
  M.stop()
  M.start()
end

function M.is_running()
  return state.osc_running
end

return M
