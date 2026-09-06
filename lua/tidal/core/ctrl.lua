local config = require("tidal.config")
local notify = require("tidal.util.notify")

local M = {}

local ctrl_values = {}
local listeners = {}

function M.get(key)
  return ctrl_values[key]
end

function M.get_all()
  return vim.deepcopy(ctrl_values)
end

function M.on_change(key, callback)
  if not listeners[key] then
    listeners[key] = {}
  end
  table.insert(listeners[key], callback)
end

function M.remove_listener(key, callback)
  if not listeners[key] then
    return
  end
  for i, cb in ipairs(listeners[key]) do
    if cb == callback then
      table.remove(listeners[key], i)
      return
    end
  end
end

function M.dispatch(msg)
  if msg.address ~= "/ctrl" then
    return
  end

  local key = msg[1]
  local raw = msg[2]
  if not key then
    return
  end

  local value
  if type(raw) == "number" then
    value = raw
  elseif type(raw) == "string" then
    value = tonumber(raw) or raw
  else
    value = raw
  end

  ctrl_values[key] = value

  if config.options.osc.ctrl_debug then
    vim.schedule(function()
      notify.info(string.format("/ctrl %s = %s", key, tostring(value)))
    end)
  end

  for _, table_key in ipairs({ key, "*" }) do
    local list = listeners[table_key]
    if list then
      local snapshot = {}
      for i = 1, #list do
        snapshot[i] = list[i]
      end
      vim.schedule(function()
        for _, cb in ipairs(snapshot) do
          local ok, err = pcall(cb, key, value)
          if not ok then
            notify.error(string.format("/ctrl listener error for %s: %s", table_key, err))
          end
        end
      end)
    end
  end
end

function M.reset()
  ctrl_values = {}
end

return M
