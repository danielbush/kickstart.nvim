-- Import search utilities
local search_utils = require 'search_utils'

vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jf', '/(fun)<CR>zv', { noremap = true, silent = true, desc = '(fun)' })
-- jump headings
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jh', '/^#.*<CR>zv', { noremap = true, silent = true, desc = 'Jump headings' })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jt', '/\\<TARGETS<CR>zv', { noremap = true, silent = true, desc = 'Jump targets' })
-- collapse level 3+
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>,', 'zmzr', { noremap = true, silent = true, desc = 'Collapse level3+' })
-- jump hats
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jH', '/# i:\\S\\+_HAT\\><CR>zv', { noremap = true, silent = true, desc = 'Jump hats' })
-- jump checkboxes
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jx', '/^- <CR>zv', { noremap = true, silent = true, desc = 'Jump checkboxes' })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>h', '/r:HEADLINE<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>ja', '/#.*r:ACTION_ITEMS\\|#.*.:PLANNER<CR>zv', { noremap = true, silent = true, desc = 'Jump action items' })
-- Jump to i-alias
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>ji', 'Eyiw/i:<C-R>"\\><CR>zv', { noremap = true, silent = true, desc = 'Jump to i-alias' })
-- Jump all alias instances
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>jr', 'Eyiw/[ir]:<C-R>"<CR>zv', { noremap = true, silent = true, desc = 'Jump to i/r-aliases' })

-- Create user commands
-- vim.api.nvim_create_user_command('FindIIdentifiers', fuzzy_search_i_identifiers, {
--   desc = 'Fuzzy search for i: identifiers in current buffer',
-- })

-- Generic command that accepts a pattern as argument
-- vim.api.nvim_create_user_command('FindPattern', function(opts)
--   local pattern = opts.args
--   if pattern == '' then
--     vim.notify('Please provide a pattern. Usage: :FindPattern <pattern>', vim.log.levels.ERROR)
--     return
--   end
--   fuzzy_search_pattern(pattern, 'matches', 'Pattern Matches')
-- end, {
--   desc = 'Fuzzy search for a custom pattern in current buffer',
--   nargs = 1,
-- })

local function fuzzy_search_i_identifiers()
  search_utils.fuzzy_search_pattern('i:[A-Z0-9_]+', 'i: identifiers', 'i: Identifiers', false)
end
vim.keymap.set('n', '<localleader>fi', fuzzy_search_i_identifiers, { desc = 'Find i: identifiers' })

local function fuzzy_search_ir_identifiers()
  search_utils.fuzzy_search_pattern('[ir]:[A-Z0-9_]+', 'i/r: identifiers', 'i/r: Identifiers', true)
end
vim.keymap.set('n', '<localleader>fr', fuzzy_search_ir_identifiers, { desc = 'Find i/r: identifiers' })

local function fuzzy_search_headings()
  search_utils.fuzzy_search_pattern('^#.*$', 'Headings', 'Headings', false)
end
vim.keymap.set('n', '<localleader>fh', fuzzy_search_headings, { desc = 'Search headings' })
-- vim.keymap.set('n', '<leader>fp', function()
--   vim.ui.input({ prompt = 'Pattern: ' }, function(pattern)
--     if pattern then fuzzy_search_pattern(pattern, "matches", "Pattern Matches") end
--   end)
-- end, { desc = 'Find custom pattern' })
