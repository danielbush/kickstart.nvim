return {
  'kylechui/nvim-surround',
  version = '^3.0.0', -- for stability
  event = 'VeryLazy',
  config = function()
    require('nvim-surround').setup {}
  end,
}
