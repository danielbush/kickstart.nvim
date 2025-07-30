vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>f', '/(fun)<CR>zv', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>t', '/^#.*<CR>zv', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>\\', 'zmzr', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>h', '/# i:\\S\\+_HAT\\><CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>ha', '?i:A_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>hi', '?i:I_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>he', '?i:HE_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>hb', '?i:B_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>he', '?i:E_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>hd', '?i:D_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>hm', '?i:M_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>hu', '?i:MU_HAT<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/ \\[.\\] <CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/^- \\[.\\] <CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/^- ....<CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/^- \\[.\\] \\|^- \\ze[^[]<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/^- <CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>h', '/r:HEADLINE<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>a', '/#.*r:ACTION_ITEMS\\|#.*.:PLANNER<CR>zv', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>c', '/#.*r:CONCERNS<CR>zv', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>I', 'Eyiw/i:<C-R>"<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>i', 'Eyiw/[ir]:<C-R>"<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>r', '/[ir]:\\S\\+<CR>', { noremap = true, silent = true })

-- Function to find all i: identifiers in the current buffer
local function find_i_identifiers()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local identifiers = {}
  local pattern = 'i:[A-Z_]+'

  for line_num, line in ipairs(lines) do
    local start_pos = 1
    while true do
      local match_start, match_end = string.find(line, pattern, start_pos)
      if not match_start then
        break
      end

      local identifier = string.sub(line, match_start, match_end)
      table.insert(identifiers, {
        text = identifier,
        line = line_num,
        col = match_start,
        display = string.format('%s (line %d, col %d)', identifier, line_num, match_start),
      })

      start_pos = match_end + 1
    end
  end

  return identifiers
end

-- Function to jump to the selected identifier
local function jump_to_identifier(item)
  vim.api.nvim_win_set_cursor(0, { item.line, item.col - 1 })
  vim.cmd 'normal! zv'
  vim.cmd 'normal! zz' -- Center the line on screen
end

-- Main fuzzy search function
local function fuzzy_search_i_identifiers()
  local identifiers = find_i_identifiers()

  if #identifiers == 0 then
    vim.notify('No i: identifiers found in current buffer', vim.log.levels.INFO)
    return
  end

  -- Check if telescope is available
  local has_telescope, telescope = pcall(require, 'telescope')
  if has_telescope then
    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    pickers
      .new({}, {
        prompt_title = 'i: Identifiers',
        finder = finders.new_table {
          results = identifiers,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.display,
              ordinal = entry.text,
            }
          end,
        },
        sorter = conf.generic_sorter {},
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            jump_to_identifier(selection.value)
          end)
          return true
        end,
      })
      :find()
  else
    -- Fallback to vim.ui.select if Telescope is not available
    local display_items = {}
    for _, item in ipairs(identifiers) do
      table.insert(display_items, item.display)
    end

    vim.ui.select(display_items, {
      prompt = 'Select i: identifier:',
    }, function(choice, idx)
      if choice and idx then
        jump_to_identifier(identifiers[idx])
      end
    end)
  end
end

-- Create a user command
vim.api.nvim_create_user_command('FindIIdentifiers', fuzzy_search_i_identifiers, {
  desc = 'Fuzzy search for i: identifiers in current buffer',
})

-- Optional: Create a keymap (uncomment the line below if you want a default keybinding)
vim.keymap.set('n', '<localleader>j', fuzzy_search_i_identifiers, { desc = 'Find i: identifiers' })

-- Return the function so it can be called directly if needed
-- return fuzzy_search_i_identifiers
