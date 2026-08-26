local Repl = require("tidal.util.repl.repl")

local Sclang = Repl:new()
Sclang.__index = Sclang

return Sclang
