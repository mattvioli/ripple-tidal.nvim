local parser = require("tidal.completion.parser")
local symbols = require("tidal.completion.symbols")
local config = require("tidal.config")
local notify = require("tidal.util.notify")

local M = {}

local notified = false
local checking = false

local function current_context()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local buf = vim.api.nvim_win_get_buf(0)
  return parser.get_context(buf, row, col)
end

local function prefix_len(ctx)
  if ctx.type == "sample" or ctx.type == "index" or ctx.type == "param_value"
    or ctx.type == "keyword" then
    return (ctx.prefix or ""):len()
  end
  return 0
end

function M.complete(findstart, base)
  if findstart == 1 then
    local ctx = current_context()

    if not parser.is_ts_available() and not notified then
      notified = true
      notify.info("tidal-ripple autocomplete: nvim-treesitter with haskell parser recommended for best results")
    end

    local col = vim.fn.col(".") - 1
    local startcol = col - prefix_len(ctx) + 1
    if startcol < 1 then startcol = 1 end
    return startcol
  end

  local ctx = current_context()
  return parser.get_completions(ctx)
end

local function should_autocomplete(ctx)
  if not ctx or not ctx.type then return false end
  if ctx.type == "empty" then return false end
  if ctx.type == "param" or ctx.type == "function" then return true end
  if ctx.type == "sample" or ctx.type == "index" or ctx.type == "param_value" then
    return (ctx.prefix or "") ~= ""
  end
  if ctx.type == "keyword" then
    return (ctx.prefix or ""):len() >= 2
  end
  return false
end

local function popup()
  if checking then return end
  checking = true
  vim.schedule(function()
    if vim.fn.pumvisible() == 1 then
      checking = false
      return
    end
    local ctx = current_context()
    if should_autocomplete(ctx) then
      vim.fn.complete(vim.fn.col(".") - prefix_len(ctx), parser.get_completions(ctx))
    end
    checking = false
  end)
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

    vim.api.nvim_create_autocmd("TextChangedI", {
      pattern = "*.tidal",
      callback = popup,
    })
  end
end

return M
