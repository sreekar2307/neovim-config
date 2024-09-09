local M = {}
local ms = require('vim.lsp.protocol').Methods

local text_node_types = { 'comment', 'string', 'string_literal', 'block_comment' }

local ts_utils = require 'nvim-treesitter.ts_utils'

M.replace_text_in_row = function(buf, row, start_col, new_text, cover_length)
  local text_snip = function()
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    local updated_line = string.sub(line, 1, start_col - 1) .. new_text .. string.sub(line, start_col + cover_length)
    vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { updated_line })
  end

  local text_node = function()
    local node = ts_utils.get_node_at_cursor()

    if node == nil then
      return false
    end

    local node_type = node:type()

    for _, text_type in ipairs(text_node_types) do
      if node_type == text_type then
        return true
      end
    end
    return false
  end

  local clients = vim.lsp.get_clients {
    bufnr = buf,
    method = ms.textDocument_rename,
  }
  if #clients > 0 then
    vim.lsp.buf.rename(new_text, {
      bufnr = buf,
    })
    if text_node() then
      text_snip()
    end
  else
    text_snip() -- if no lsp servers are available or the rename
  end
end

return M
