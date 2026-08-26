local Buffer = require("tidal.util.buffer")

local Repl = {}
Repl.__index = Repl

function Repl:new(opts)
  opts = opts or {}
  local obj = {}
  setmetatable(obj, self)
  obj.buf = Buffer.new({ name = opts.name, scratch = true, listed = false })
  obj.opts = opts
  obj.win_id = nil
  return obj
end

function Repl:start(opts)
  if self.proc == nil then
    local win_opts = opts or {}
    self.win_id = self.buf:show(win_opts)
    self.proc = vim.fn.jobstart(vim.list_extend({ self.opts.cmd }, self.opts.args or {}), {
      term = true,
      on_exit = function(code, signal)
        self.proc = nil
        self.win_id = nil
        if self.opts.on_exit then
          self.opts.on_exit(code, signal)
        end
      end,
    })
  end
  return self
end

function Repl:send(text)
  if self.proc == nil then
    return self
  end
  vim.api.nvim_chan_send(self.proc, text)
  self.buf:scroll_to_bottom()
  return self
end

function Repl:send_line(text)
  return self:send(text .. "\n")
end

function Repl:send_multiline(lines)
  return self:send_line(table.concat(lines, "\n"))
end

function Repl:exit()
  if self.proc then
    vim.fn.jobstop(self.proc)
  end
  return self
end

function Repl:is_running()
  return self.proc ~= nil
end

return Repl
