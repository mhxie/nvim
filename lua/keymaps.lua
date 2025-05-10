-- Modernized keymaps using vim.keymap.set

-- Copy to clipboard
vim.keymap.set({'n', 'v', 'o'}, '<leader>c', '"+y', { desc = "Copy to clipboard" })

-- Undo-friendly <C-u> and <C-w> in insert mode
vim.keymap.set('i', '<C-u>', '<C-g>u<C-u>', { desc = "Undo-friendly C-u" })
vim.keymap.set('i', '<C-w>', '<C-g>u<C-w>', { desc = "Undo-friendly C-w" })

-- <Tab> and <S-Tab> to navigate completion menu
vim.keymap.set('i', '<S-Tab>', function() return vim.fn.pumvisible() == 1 and "\\<C-p>" or "\\<S-Tab>" end, { expr = true, silent = true, desc = "Navigate completion up" })
vim.keymap.set('i', '<Tab>', function() return vim.fn.pumvisible() == 1 and "\\<C-n>" or "\\<Tab>" end, { expr = true, silent = true, desc = "Navigate completion down" })

-- Clear highlights
vim.keymap.set('n', '<C-l>', '<cmd>noh<CR>', { silent = true, desc = "Clear highlights" })

-- Insert a newline in normal mode (original behavior)
vim.keymap.set('n', '<leader>o', function()
  vim.cmd('normal! m`')
  vim.cmd('normal! o')
  vim.cmd('normal! ``') -- Jumps back to the mark, then to the line before insert
end, { desc = "Insert newline below (original behavior)" })

-- Show diagnostics in a floating window
vim.keymap.set('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', { silent = true, desc = "Show diagnostics" })

-- Telescope mappings
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = "Telescope Find Files" })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', { desc = "Telescope Live Grep" })
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { desc = "Telescope Buffers" })
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', { desc = "Telescope Help Tags" }) 