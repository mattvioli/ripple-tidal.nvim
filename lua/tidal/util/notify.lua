local M = {}

function M.info(msg)
  vim.notify("[tidal-ripple] " .. msg, vim.log.levels.INFO)
end

function M.warn(msg)
  vim.notify("[tidal-ripple] " .. msg, vim.log.levels.WARN)
end

function M.error(msg)
  vim.notify("[tidal-ripple] " .. msg, vim.log.levels.ERROR)
end

return M
