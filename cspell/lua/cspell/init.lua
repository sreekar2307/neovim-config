local util = require 'cspell.util'

local M = {
  corrections = {},
}

M.code_spell = function()
  local handle = io.popen('cspell --quiet --show-suggestions --cache --no-exit-code .' .. ' 2>&1')
  if handle ~= nil then
    local cmd_output = handle:read '*a'
    handle:close()
    local spell_results = {}

    for line in cmd_output:gmatch '[^\r\n]+' do
      local file, row, col, incorrect_word, suggestions_str = line:match '([^:]+):(%d+):(%d+) %- Unknown word %(([^)]+)%) Suggestions: %[(.+)%]'

      if file and row and col and incorrect_word and suggestions_str then
        -- Convert row and col to numbers
        row = tonumber(row)
        col = tonumber(col)

        -- Split the suggestions string into a table
        local suggestions = {}
        for suggestion in suggestions_str:gmatch '[^, ]+' do
          table.insert(suggestions, suggestion)
        end

        -- Create the result table for this line
        local result = {
          file = file,
          loc = {
            row = row,
            col = col,
          },
          incorrect_word = incorrect_word,
          suggestions = suggestions,
        }
        table.insert(spell_results, result)
      end
    end
    M.corrections = spell_results
    local quickfix_list = {}
    for _, item in ipairs(M.corrections) do
      table.insert(quickfix_list, {
        filename = item.file,
        lnum = item.loc.row,
        col = item.loc.col,
        text = string.format('Unknown word: %s. Suggestions: %s', item.incorrect_word, table.concat(item.suggestions, ', ')),
      })
    end
    vim.fn.setqflist(quickfix_list, 'r')
    if #quickfix_list > 0 then
      vim.cmd 'copen'
    else
      print 'No misspelled words found'
      vim.cmd 'cclose'
    end
  end
end

M.show_word_suggestions = function()
  local winid = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(winid))
  col = col + 1 -- adjust to 1-based index
  vim.cmd 'normal! eb'
  local word = vim.fn.expand '<cword>'
  local buf = vim.api.nvim_get_current_buf()

  local _, word_start_col = unpack(vim.api.nvim_win_get_cursor(winid))
  word_start_col = word_start_col + 1 -- adjust to 1-based index

  vim.api.nvim_win_set_cursor(winid, { row, col - 1 })

  if #M.corrections == 0 then
    print 'call CSpell to populate misspelled words'
    return
  end

  for _, item in ipairs(M.corrections) do
    local curr_suggestions = {}
    if item.loc.row == row and item.loc.col == col then
      for _, suggestion in ipairs(item.suggestions) do
        local curr_suggestion = string.gsub(word, item.incorrect_word, suggestion)
        table.insert(curr_suggestions, curr_suggestion)
      end
      M.show_suggestions(curr_suggestions, buf, row, word_start_col, #word)
      return
    end
  end
  print 'no suggestions found for word'
end

M.show_suggestions = function(suggestions, main_buf, main_row, replace_line_start_col, cover_length)
  local ordered_suggestions = {}
  table.insert(ordered_suggestions, 'Choose Suggestion')
  for index, suggestion in ipairs(suggestions) do
    table.insert(ordered_suggestions, string.format('%d. %s', index, suggestion))
  end
  local selected_spell_index = vim.fn.inputlist(ordered_suggestions)
  if selected_spell_index == 0 then
    return
  end
  local selected_suggestion = suggestions[selected_spell_index]
  util.replace_text_in_row(main_buf, main_row, replace_line_start_col, selected_suggestion, cover_length)
end

vim.api.nvim_set_keymap('n', '<leader>mss', "<cmd>lua require('cspell').show_word_suggestions()<CR>", {
  noremap = true,
  silent = true,
  desc = '[M]iss [S]pell [S]uggestions',
})

vim.api.nvim_set_keymap('n', '<leader>msq', "<cmd>lua require('cspell').code_spell()<CR>", {
  noremap = true,
  silent = true,
  desc = '[M]iss [S]pell [Q]uickfix',
})

vim.api.nvim_create_user_command('CodeSpell', function()
  M.code_spell()
end, {})

return M
