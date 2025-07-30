-- Function to find all matches for a given pattern in the current buffer
local function find_pattern_matches(pattern, pattern_name, show_line)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local matches = {}

  for line_num, line in ipairs(lines) do
    local start_pos = 1
    while true do
      local match_start, match_end = string.find(line, pattern, start_pos)
      if not match_start then
        break
      end

      local match_text = string.sub(line, match_start, match_end)
      table.insert(matches, {
        text = match_text,
        line = line_num,
        col = match_start,
        display = show_line and string.format('%s (line %d, col %d) %s', match_text, line_num, match_start, line)
          or string.format('%s (line %d, col %d)', match_text, line_num, match_start),
      })

      start_pos = match_end + 1
    end
  end

  return matches, pattern_name or 'matches'
end

-- Function to jump to the selected identifier
local function jump_to_identifier(item)
  vim.api.nvim_win_set_cursor(0, { item.line, item.col - 1 })

  -- Open any folds that contain this line
  vim.cmd 'normal! zv'

  -- Center the line on screen
  vim.cmd 'normal! zz'
end

-- Generic fuzzy search function
local function fuzzy_search_pattern(pattern, pattern_name, prompt_title, show_line)
  local matches, display_name = find_pattern_matches(pattern, pattern_name, show_line)

  if #matches == 0 then
    vim.notify(string.format('No %s found in current buffer', display_name), vim.log.levels.INFO)
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
        prompt_title = prompt_title or display_name,
        finder = finders.new_table {
          results = matches,
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
    for _, item in ipairs(matches) do
      table.insert(display_items, item.display)
    end

    vim.ui.select(display_items, {
      prompt = string.format('Select %s:', display_name),
    }, function(choice, idx)
      if choice and idx then
        jump_to_identifier(matches[idx])
      end
    end)
  end
end

-- Multi-word search function with live telescope filtering
local function live_multiword_search()
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    vim.notify('Telescope not available', vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local all_lines = {}
  for line_num, line in ipairs(lines) do
    table.insert(all_lines, {
      text = line,
      line = line_num,
      col = 1,
      display = string.format('Line %d: %s', line_num, line),
    })
  end

  pickers
    .new({}, {
      prompt_title = 'Multi-word Search (space-separated)',
      finder = finders.new_dynamic {
        fn = function(prompt)
          if not prompt or prompt == '' then
            return all_lines
          end

          -- Split prompt into words
          local words = {}
          for word in prompt:gmatch '%S+' do
            table.insert(words, word)
          end

          if #words == 0 then
            return all_lines
          end

          local filtered_lines = {}
          for _, item in ipairs(all_lines) do
            local line_matches_all = true

            -- Check if all words are present as whole words in the line
            for _, word in ipairs(words) do
              -- Use Lua pattern matching for whole words with case-insensitive search
              -- local escaped_word = word:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
              -- local word_pattern = '%f[%w]' .. escaped_word .. '%f[%W]'
              -- if not string.find(item.text:lower(), word_pattern:lower()) then
              if not string.find(item.text:lower(), word:lower()) then
                line_matches_all = false
                break
              end
            end

            if line_matches_all then
              table.insert(filtered_lines, item)
            end
          end

          return filtered_lines
        end,
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
end

vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>f', '/(fun)<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>t', '/^#.*<CR>zv', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>\\', 'zmzr', { noremap = true, silent = true })
-- jump hats
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>H', '/# i:\\S\\+_HAT\\><CR>', { noremap = true, silent = true })
-- jump checkboxes
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>x', '/^- <CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>h', '/r:HEADLINE<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>a', '/#.*r:ACTION_ITEMS\\|#.*.:PLANNER<CR>zv', { noremap = true, silent = true })
-- Jump to i-alias
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>I', 'Eyiw/i:<C-R>"<CR>zv', { noremap = true, silent = true })
-- Jump all alias instances
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>r', 'Eyiw/[ir]:<C-R>"<CR>zv', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>r', '/[ir]:\\S\\+<CR>', { noremap = true, silent = true })

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
  fuzzy_search_pattern('i:[A-Z0-9_]+', 'i: identifiers', 'i: Identifiers', false)
end
vim.keymap.set('n', '<localleader>j', fuzzy_search_i_identifiers, { desc = 'Find i: identifiers' })
local function fuzzy_search_ir_identifiers()
  fuzzy_search_pattern('[ir]:[A-Z0-9_]+', 'i/r: identifiers', 'i/r: Identifiers', true)
end
vim.keymap.set('n', '<localleader>J', fuzzy_search_ir_identifiers, { desc = 'Find i: identifiers' })

local function fuzzy_search_headings()
  fuzzy_search_pattern('^#.*$', 'Headings', 'Headings', false)
end
vim.keymap.set('n', '<localleader>h', fuzzy_search_headings, { desc = 'Search headings' })

vim.keymap.set('n', '<localleader>w', live_multiword_search, { desc = 'Multi-word search' })
-- vim.keymap.set('n', '<leader>fp', function()
--   vim.ui.input({ prompt = 'Pattern: ' }, function(pattern)
--     if pattern then fuzzy_search_pattern(pattern, "matches", "Pattern Matches") end
--   end)
-- end, { desc = 'Find custom pattern' })
