local notify = require("tidal.util.notify")
local util = require("tidal.util")

local M = {}

local function get_mark(mode)
  local start_char, end_char = unpack(({ visual = { "<", ">" }, motion = { "[", "]" } })[mode])
  local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, start_char))
  local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, end_char))
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return {
    start = { start_line - 1, start_col },
    finish = { end_line - 1, end_col },
    lines = selected_lines,
  }
end

function M.get_visual()
  local mode = vim.fn.visualmode()
  local range = get_mark("visual")
  if mode == "V" then
    return range
  end
  if mode == "v" then
    local start_line, start_col = unpack(range.start)
    local finish_line, finish_col = unpack(range.finish)
    if vim.opt.selection:get() == "exclusive" then
      finish_col = finish_col - 1
    end
    return {
      lines = vim.api.nvim_buf_get_text(0, start_line, start_col, finish_line, finish_col + 1, {}),
      start = { start_line, start_col },
      finish = { finish_line, finish_col },
    }
  end
  if mode == "\x16" then
    local start_line = range.start[1]
    local finish_line = range.finish[1]
    return {
      lines = vim.api.nvim_buf_get_lines(0, start_line, finish_line + 1, false),
      start = range.start,
      finish = range.finish,
    }
  end
end

function M.get_current_line()
  local line = unpack(vim.api.nvim_win_get_cursor(0), 1) - 1
  local text = vim.api.nvim_get_current_line()
  return {
    lines = { text },
    start = { line, 0 },
    finish = { line, #text },
  }
end

function M.get_block()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local block_start = row - 1
  while block_start > 0 and not util.line_empty(block_start - 1) do
    block_start = block_start - 1
  end
  local block_end = row
  local n_lines = vim.api.nvim_buf_line_count(0)
  while block_end < n_lines and not util.line_empty(block_end) do
    block_end = block_end + 1
  end
  local lines = vim.api.nvim_buf_get_lines(0, block_start, block_end, true)
  return {
    lines = lines,
    start = { block_start, 0 },
    finish = { block_end, #lines[#lines] },
  }
end

local node_types = {
  haskell = {
    expression = { "top_splice", "exp", "bind", "function" },
    skip = { "haskell", "declarations" },
  },
  supercollider = {
    expression = { "code_block" },
  },
}

function M.get_node()
  local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  local lang = vim.treesitter.language.get_lang(ft)
  if lang == nil then
    notify.error("No treesitter parser for '" .. ft .. "'")
    return
  end
  local nodes = node_types[lang]
  local node = vim.treesitter.get_node()
  if not node or vim.tbl_contains(nodes.skip or {}, node:type()) then
    return
  end
  local root = node:tree():root()
  if not root then
    return
  end
  local parent = node:parent()
  local break_nodes = nodes.expression or {}
  while node ~= nil and not node:equal(root) do
    local node_t = node:type()
    if vim.list_contains(break_nodes, node_t) then
      break
    end
    node = parent
    if node then
      parent = node:parent()
    end
  end
  assert(node, "node cannot be nil")
  local start_row, start_col, finish_row, finish_col = vim.treesitter.get_node_range(node)
  local bufnr = 0
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if finish_row >= line_count then
    finish_row = line_count - 1
    local last_line = vim.api.nvim_buf_get_lines(bufnr, finish_row, finish_row + 1, false)[1] or ""
    finish_col = #last_line
  end
  local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, finish_row, finish_col, {})
  return {
    start = { start_row, start_col },
    finish = { finish_row, finish_col },
    lines = lines,
  }
end

return M
