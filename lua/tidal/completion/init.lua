local parser = require("tidal.completion.parser")
local symbols = require("tidal.completion.symbols")
local config = require("tidal.config")
local notify = require("tidal.util.notify")

local M = {}

local notified = false

function M.complete(findstart, base)
  if findstart == 1 then
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local buf = vim.api.nvim_win_get_buf(0)
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

    local ctx = parser.get_context(buf, row, col)

    if not parser.is_ts_available() and not notified then
      notified = true
      notify.info("tidal-ripple autocomplete: nvim-treesitter with haskell parser recommended for best results")
    end

    local col_offset = 0
    if ctx.type == "sample" or ctx.type == "index" or ctx.type == "param_value" then
      col_offset = (ctx.prefix or ""):len()
    elseif ctx.type == "keyword" then
      col_offset = (ctx.prefix or ""):len()
    end

    local startcol = col - col_offset
    if startcol < 1 then startcol = 1 end

    return startcol
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local buf = vim.api.nvim_win_get_buf(0)
  local ctx = parser.get_context(buf, row, col)

  local matches = parser.get_completions(ctx)
  return matches
end

function M.setup()
  if not config.options.completion or config.options.completion.enabled ~= false then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "haskell",
      callback = function(args)
        if vim.bo[args.buf].filetype == "haskell" then
          vim.bo[args.buf].omnifunc = "v:lua.require'tidal.completion'.complete"
          symbols.scan_buffer(args.buf)
        end
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.tidal",
      callback = function(args)
        symbols.scan_buffer(args.buf)
      end,
    })
  end
end

return M
