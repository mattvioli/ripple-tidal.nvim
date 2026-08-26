vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.tidal",
  callback = function()
    vim.bo.filetype = "haskell"
  end,
})
