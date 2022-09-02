-------------------- HELPERS -------------------------------
local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables
local opt = vim.opt  -- to set options

local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-------------------- PLUGINS -------------------------------
require 'paq' {
    'savq/paq-nvim';                 -- paq-nvim manages itself

    'navarasu/onedark.nvim';
    'yorik1984/newpaper.nvim';
    'shougo/deoplete-lsp';
    {'shougo/deoplete.nvim', run = fn['remote#host#UpdateRemotePlugins']};
    {'nvim-treesitter/nvim-treesitter', run = fn['TSUpdate']};
    'neovim/nvim-lspconfig';
    'nvim-lua/lsp_extensions.nvim';
    'nvim-lua/plenary.nvim';
    'nvim-telescope/telescope.nvim';
    'kyazdani42/nvim-web-devicons';
    'ojroques/nvim-hardline';
    'nvim-lua/plenary.nvim';
    'lewis6991/gitsigns.nvim';      -- git decorations implemented purely in lua/teal
    'tpope/vim-fugitive';
    'rust-lang/rust.vim';
    -- {'simrat39/rust-tools.nvim'}
    'python/black';
    'rhysd/vim-clang-format';
}
g['onedark_style'] = 'warmer'
g['newpaper_style'] = 'dark'
g['deoplete#enable_at_startup'] = 1  -- enable deoplete at startup
g['rustfmt_autosave'] = 1            -- Enable Rust auto format

-------------------- OPTIONS -------------------------------
opt.completeopt = {'menuone', 'noinsert', 'noselect'}  -- Completion options (for deoplete)
opt.expandtab = true                -- Use spaces instead of tabs
opt.hidden = true                   -- Enable background buffers
opt.ignorecase = true               -- Ignore case
opt.joinspaces = false              -- No double spaces with join
opt.list = true                     -- Show some invisible characters
opt.number = true                   -- Show line numbers
opt.relativenumber = true           -- Relative line numbers
opt.scrolloff = 4                   -- Lines of context
opt.shiftround = true               -- Round indent
opt.shiftwidth = 2                  -- Size of an indent
opt.sidescrolloff = 8               -- Columns of context
opt.smartcase = true                -- Do not ignore case with capitals
opt.smartindent = true              -- Insert indents automatically
opt.splitbelow = true               -- Put new windows below current
opt.splitright = true               -- Put new windows right of current
opt.tabstop = 2                     -- Number of spaces tabs count for
opt.termguicolors = true            -- True color support
opt.wildmode = {'list', 'longest'}  -- Command-line completion mode
opt.wrap = false                    -- Disable line wrap

-------------------- MAPPINGS ------------------------------
map('', '<leader>c', '"+y')       -- Copy to clipboard in normal, visual, select and operator modes
map('i', '<C-u>', '<C-g>u<C-u>')  -- Make <C-u> undo-friendly
map('i', '<C-w>', '<C-g>u<C-w>')  -- Make <C-w> undo-friendly

-- <Tab> to navigate the completion menu
map('i', '<S-Tab>', 'pumvisible() ? "\\<C-p>" : "\\<Tab>"', {expr = true})
map('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : "\\<Tab>"', {expr = true})

map('n', '<C-l>', '<cmd>noh<CR>')    -- Clear highlights
map('n', '<leader>o', 'm`o<Esc>``')  -- Insert a newline in normal mode

-------------------- TREE-SITTER ---------------------------
local ts = require 'nvim-treesitter.configs'
ts.setup {
  ensure_installed = {'c', 'cpp', 'python', 'rust', 'lua'},
  highlight = {
    enable = true,
    -- disable = {'cpp'} -- disable cpp parser before getting an upstream fix
  },
}

-------------------- PRETTY-NEOVIM ---------------------------
require('newpaper').setup {}
-- require('onedark').setup {}
-- vim.cmd[[colorscheme tokyonight]]
require('hardline').setup {}
require('gitsigns').setup {}
require('telescope').setup{}
-- cmd 'colorscheme PaperColor'           -- Put your favorite colorscheme here

-------------------- LSP -----------------------------------
local lsp = require 'lspconfig'

-- For ccls we use the default settings
lsp.ccls.setup {}
lsp.pylsp.setup {}
lsp.rust_analyzer.setup({ on_attach=on_attach })

map('n', '<space>,', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
map('n', '<space>;', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
map('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<CR>')
map('n', '<space>d', '<cmd>lua vim.lsp.buf.definition()<CR>')
map('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
map('n', '<space>h', '<cmd>lua vim.lsp.buf.hover()<CR>')
map('n', '<space>m', '<cmd>lua vim.lsp.buf.rename()<CR>')
map('n', '<space>r', '<cmd>lua vim.lsp.buf.references()<CR>')
map('n', '<space>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')

-------------------- Telescope ---------------------------
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>')
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>')
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>')

-------------------- COMMANDS ------------------------------
cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'  -- disabled in visual mode
cmd 'autocmd BufWritePre *.py execute \':Black\''
cmd 'autocmd FileType c,cpp ClangFormatAutoEnable'
