local search_utils = require 'search_utils'

vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gf', '/(fun)<CR>zv', { noremap = true, silent = true, desc = '(fun)' })
-- jump headings
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gh', '/^#.*<CR>zv', { noremap = true, silent = true, desc = 'Jump headings' })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gt', '/r:TARGETS<CR>zv', { noremap = true, silent = true, desc = 'Jump targets' })
-- collapse level 3+
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>,', 'zmzr', { noremap = true, silent = true, desc = 'Collapse level3+' })
-- jump hats
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gH', '/# i:\\S\\+_HAT\\><CR>zv', { noremap = true, silent = true, desc = 'Jump hats' })
-- jump checkboxes
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gx', '/^- <CR>zv', { noremap = true, silent = true, desc = 'Jump checkboxes' })
-- vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>h', '/r:HEADLINE<CR>', { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>ga', '/#.*r:ACTION_ITEMS\\|#.*.:PLANNER<CR>zv', { noremap = true, silent = true, desc = 'Jump action items' })
-- Jump to i-alias
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gi', 'Eyiw/i:<C-R>"\\><CR>zv', { noremap = true, silent = true, desc = 'Jump to i-alias' })
-- Jump all alias instances
vim.api.nvim_buf_set_keymap(0, 'n', '<localleader>gr', 'Eyiw/[ir]:<C-R>"<CR>zv', { noremap = true, silent = true, desc = 'Jump to i/r-aliases' })

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
-- vim.keymap.set('n', '<localleader>i', fuzzy_search_i_identifiers, { desc = 'Find i: identifiers' })

local function fuzzy_search_ir_identifiers()
  search_utils.fuzzy_search_pattern('[ir]:[A-Z0-9_]+', 'i/r: identifiers', 'i/r: Identifiers', true)
end
vim.keymap.set('n', '<localleader>fr', fuzzy_search_ir_identifiers, { desc = 'Find i/r: identifiers' })

local function fuzzy_search_headings()
  search_utils.fuzzy_search_pattern('^#.*$', 'Headings', 'Headings', false)
end
vim.keymap.set('n', '<localleader>fh', fuzzy_search_headings, { desc = 'Search headings' })
vim.keymap.set('n', '<localleader>h', fuzzy_search_headings, { desc = 'Search headings' })

local function fuzzy_insert_i_identifiers()
  search_utils.fuzzy_search_pattern_insert_convert_i_to_r('i:[A-Z0-9_]+', 'i: identifiers', 'Insert r: Identifiers', false)
end
vim.keymap.set('n', '<localleader>ii', fuzzy_insert_i_identifiers, { desc = 'Insert r: identifiers' })
-- vim.keymap.set('n', '<leader>fp', function()
--   vim.ui.input({ prompt = 'Pattern: ' }, function(pattern)
--     if pattern then fuzzy_search_pattern(pattern, "matches", "Pattern Matches") end
--   end)
-- end, { desc = 'Find custom pattern' })

--------------------------------------------------------------------------------
-- Folding
--------------------------------------------------------------------------------
--
-- Default method - doens't handle codeblocks eg python code with '#' comments
--
-- vim.cmd 'set foldmethod=expr'
-- vim.cmd 'set foldexpr=NestedMarkdownFolds()'
--
-- https://vi.stackexchange.com/questions/21687/how-to-prevent-markdown-folding-of-comments-in-fenced-code
-- This uses syntax, but I can't get it to work.
-- This solution from claude handles heading folds around code blocks by looking for backticks rather than syntax and is reasonably performant.
--
if true then
  -- Cache for code block detection to avoid O(n²) performance
  local code_block_cache = {}
  local last_file_change = 0

  local function markdown_fold()
    local lnum = vim.v.lnum
    local line = vim.fn.getline(lnum)

    -- Check if file has changed and clear cache if needed
    local current_change = vim.fn.changenr()
    if current_change ~= last_file_change then
      code_block_cache = {}
      last_file_change = current_change
    end

    -- Optimized code block detection with caching
    local function is_in_code_block()
      -- Check cache first
      if code_block_cache[lnum] ~= nil then
        return code_block_cache[lnum]
      end

      -- Build cache for current line and any missing previous lines
      local in_fenced = false
      local fence_pattern = nil
      local start_line = 1

      -- Find the highest cached line before current line
      for i = lnum - 1, 1, -1 do
        if code_block_cache[i] ~= nil then
          start_line = i + 1
          -- Get the state from the cached line
          in_fenced = code_block_cache[i].in_fenced or false
          fence_pattern = code_block_cache[i].fence_pattern
          break
        end
      end

      -- Process lines from start_line to current line
      for i = start_line, lnum do
        local check_line = vim.fn.getline(i)

        -- Check for opening/closing fences
        local triple_backtick = check_line:match '^```'
        local triple_tilde = check_line:match '^~~~'

        if triple_backtick then
          if not in_fenced then
            in_fenced = true
            fence_pattern = 'backtick'
          elseif fence_pattern == 'backtick' then
            in_fenced = false
            fence_pattern = nil
          end
        elseif triple_tilde then
          if not in_fenced then
            in_fenced = true
            fence_pattern = 'tilde'
          elseif fence_pattern == 'tilde' then
            in_fenced = false
            fence_pattern = nil
          end
        end

        -- Cache the state for this line
        code_block_cache[i] = {
          in_fenced = in_fenced,
          fence_pattern = fence_pattern,
        }
      end

      -- Check for indented code blocks (4 spaces or 1 tab)
      if not in_fenced then
        local current_line = vim.fn.getline(lnum)
        if current_line:match '^    ' or current_line:match '^\t' then
          -- Check if previous line is also indented or empty
          local prev_line = vim.fn.getline(lnum - 1)
          if prev_line:match '^%s*$' or prev_line:match '^    ' or prev_line:match '^\t' then
            return true
          end
        end
      end

      return in_fenced
    end

    -- Regular headers (but only if not in code block)
    local hash_count = line:match '^(#+)%s'
    if hash_count then
      if not is_in_code_block() then
        local depth = #hash_count
        return '>' .. depth
      end
      -- If we're in a code block, ignore the # and continue with normal logic
    end

    -- Setext style headings (only check if not in code block)
    if not is_in_code_block() then
      local prevline = vim.fn.getline(lnum - 1)
      local nextline = vim.fn.getline(lnum + 1)

      -- Check if current line is setext heading content
      if line:match '^.+$' and nextline:match '^=+$' and prevline:match '^%s*$' then
        return '>1'
      end

      if line:match '^.+$' and nextline:match '^-+$' and prevline:match '^%s*$' then
        return '>2'
      end

      -- Check if current line is setext underline
      if line:match '^=+$' then
        return '='
      end

      if line:match '^-+$' then
        return '='
      end
    end

    -- Frontmatter
    if lnum == 1 and line:match '^----*$' then
      return '>1'
    end

    -- For non-header lines, find the most recent header (optimized)
    for i = lnum - 1, 1, -1 do
      local prev_line = vim.fn.getline(i)
      local prev_hash = prev_line:match '^(#+)%s'

      if prev_hash then
        -- Check if this header line is in a code block
        local prev_in_code = false
        if code_block_cache[i] then
          prev_in_code = code_block_cache[i].in_fenced or false
        else
          -- Quick check: if we haven't cached this line yet, do a minimal check
          -- This is still O(1) amortized due to caching
          local temp_lnum = vim.v.lnum
          vim.v.lnum = i
          prev_in_code = is_in_code_block()
          vim.v.lnum = temp_lnum
        end

        if not prev_in_code then
          return #prev_hash
        end
      end

      -- Check for setext headers
      local line_before = vim.fn.getline(i - 1)
      if prev_line:match '^=+$' and line_before:match '^.+$' then
        return '1'
      end
      if prev_line:match '^-+$' and line_before:match '^.+$' then
        return '2'
      end
    end

    return '0' -- No fold if no header found
  end

  -- Set the fold expression
  vim.opt_local.foldmethod = 'expr'
  vim.opt_local.foldexpr = 'v:lua.markdown_fold()'

  -- Make the function available globally
  _G.markdown_fold = markdown_fold
end
