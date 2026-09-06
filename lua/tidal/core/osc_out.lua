local config = require("tidal.config")
local notify = require("tidal.util.notify")
local Packet = require("tidal.lib.losc.packet")

local M = {}

local udp = nil

local function send_osc(address, args)
  local port = config.options.osc.tidal_port
  if not port then
    return
  end

  if not udp then
    udp = vim.uv.new_udp()
    if not udp then
      notify.error("OSC send: failed to create UDP socket")
      return
    end
    udp:bind("127.0.0.1", 0)
  end

  local msg = { address = address, types = "" }
  if args then
    for _, arg in ipairs(args) do
      if type(arg) == "number" then
        if arg == math.floor(arg) then
          msg.types = msg.types .. "i"
        else
          msg.types = msg.types .. "f"
        end
      elseif type(arg) == "string" then
        msg.types = msg.types .. "s"
      end
      msg[#msg + 1] = arg
    end
  end

  local ok, packed = pcall(Packet.pack, msg)
  if not ok then
    notify.error("OSC send: failed to pack message: " .. tostring(packed))
    return
  end

  udp:send(packed, "127.0.0.1", port)
end

function M.mute(orbit)
  if orbit then
    send_osc("/mute", { orbit })
  else
    send_osc("/muteAll")
  end
end

function M.unmute(orbit)
  if orbit then
    send_osc("/unmute", { orbit })
  else
    send_osc("/unmuteAll")
  end
end

function M.solo(orbit)
  if orbit then
    send_osc("/solo", { orbit })
  else
    send_osc("/muteAll")
  end
end

function M.unsolo(orbit)
  if orbit then
    send_osc("/unsolo", { orbit })
  else
    send_osc("/unsoloAll")
  end
end

function M.hush()
  send_osc("/hush")
end

function M.send_ctrl(key, value)
  send_osc("/ctrl", { key, value })
end

function M.stop()
  if udp then
    udp:close()
    udp = nil
  end
end

return M
