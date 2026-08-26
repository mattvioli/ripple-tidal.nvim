if vim.g.tidal_ripple_loaded then
  return
end
vim.g.tidal_ripple_loaded = true

require("tidal").setup()
