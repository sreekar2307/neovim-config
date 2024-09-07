local M = {}

local ms = require('vim.lsp.protocol').Methods

M.replace_text_in_row = function(buf, row, start_col, new_text, cover_length)
  local clients = vim.lsp.get_clients {
    bufnr = buf,
    method = ms.textDocument_rename,
  }

  local text_snip = function()
    while #new_text ~= cover_length do
      new_text = new_text .. ' '
    end
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    start_col = math.max(1, start_col)
    local updated_line = line:sub(1, start_col) .. new_text .. line:sub(start_col + #new_text + 1)
    vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { updated_line })
  end

  if not clients and #clients >= 1 then
    vim.lsp.buf.rename(new_text, {
      bufnr = buf,
    })
  end

  text_snip() -- if no clients are available or the rename request fails
end

return M
