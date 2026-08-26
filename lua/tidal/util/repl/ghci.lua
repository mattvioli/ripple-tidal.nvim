local Repl = require("tidal.util.repl.repl")

local Ghci = Repl:new()
Ghci.__index = Ghci

function Ghci:send_multiline(lines)
  return self:send_line(":{\n" .. table.concat(lines, "\n") .. "\n:}")
end

return Ghci
