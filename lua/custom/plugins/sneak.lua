return {
  'justinmk/vim-sneak',
  lazy = false, -- load immediately at startup
  init = function()
    -- any vim.g or vim.cmd settings for vim-sneak here
    vim.g['sneak#label'] = 1
  end,
}
