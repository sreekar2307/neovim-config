return {
  'ThePrimeagen/harpoon',
  config = function()
    require('harpoon').setup {
      enter_on_sendcmd = true,
    }
    vim.keymap.set('n', '<leader>ht', ':Telescope Harpoon marks<CR>', { desc = '[H]arpoon [T]elescope' })
    vim.keymap.set('n', '<leader>ha', require('harpoon.mark').add_file, { desc = '[H]arpoon [M]ark' })
    vim.keymap.set('n', '<leader>hq', require('harpoon.ui').toggle_quick_menu, { desc = '[H]arpoon [Q]uickMenu' })
  end,
}
