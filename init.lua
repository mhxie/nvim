-- Ensure lazy.nvim is installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-------------------- HELPERS -------------------------------
local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables
local opt = vim.opt  -- to set options

local function map(mode, lhs, rhs, opts)
  local options = {noremap = true, silent = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-------------------- LSP on_attach function ------------------
local function on_attach(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  map('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', bufopts)
  map('n', '<space>d', '<cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
  map('n', '<space>h', '<cmd>lua vim.lsp.buf.hover()<CR>', bufopts)
  map('n', '<space>m', '<cmd>lua vim.lsp.buf.rename()<CR>', bufopts)
  map('n', '<space>r', '<cmd>lua vim.lsp.buf.references()<CR>', bufopts)
  map('n', '<space>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', bufopts)

  map('n', '<space>,', '<cmd>lua vim.diagnostic.goto_prev()<CR>', bufopts)
  map('n', '<space>;', '<cmd>lua vim.diagnostic.goto_next()<CR>', bufopts)

  -- Formatting
  if client.supports_method "textDocument/formatting" then
    map('n', '<space>f', function() vim.lsp.buf.format({ bufnr = bufnr, async = true }) end, bufopts)

    -- Enable format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr, async = true })
      end,
    })
  end

  -- Add other LSP related mappings here if needed
end

-------------------- PLUGINS (lazy.nvim) ----------------------
require("lazy").setup({
  -- Core plugins
  { "folke/lazy.nvim", version = "*" }, -- lazy.nvim manages itself

  -- Colorschemes
  -- { 'navarasu/onedark.nvim' },
  -- { 'yorik1984/newpaper.nvim' },
  { "rmehri01/onenord.nvim",
    lazy = false, -- Load theme on startup
    priority = 1000, -- Ensure it's loaded first
    config = function()
      require('onenord').setup {}
      -- vim.cmd[[colorscheme onenord]] -- Set colorscheme inside config if not done automatically
    end
  },

  -- Completion
  { "shougo/deoplete.nvim",
    build = function() vim.fn['remote#host#UpdateRemotePlugins']() end,
    config = function()
      g['deoplete#enable_at_startup'] = 1
    end
  },
  { "shougo/deoplete-lsp", dependencies = { "shougo/deoplete.nvim" } },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = {'c', 'cpp', 'python', 'rust', 'lua', 'go'},
        highlight = {
          enable = true,
          -- disable = {'cpp'} -- disable cpp parser before getting an upstream fix
        },
      }
    end
  },

  -- LSP
  { "neovim/nvim-lspconfig",
    dependencies = { "rust-tools.nvim" }, -- Add rust-tools as a dependency for nvim-lspconfig
    config = function()
      local lsp = require 'lspconfig'

      -- C++: clangd setup
      lsp.clangd.setup { on_attach = on_attach }

      -- Python: pylsp and ruff_lsp setup
      lsp.pylsp.setup { on_attach = on_attach }
      lsp.ruff.setup { on_attach = on_attach }

      -- Go: gopls setup
      lsp.gopls.setup { on_attach = on_attach }

      -- Rust: rust_analyzer is typically handled by rust-tools.nvim
      -- If rust-tools.nvim doesn't automatically set it up, you might need:
      -- lsp.rust_analyzer.setup { on_attach = on_attach }
      -- But usually, rust-tools.nvim handles this.

      -- Add other LSPs here
    end
  },
  -- 'nvim-lua/lsp_extensions.nvim', -- Consider if still needed

  -- Utility
  { "nvim-lua/plenary.nvim" }, -- Common dependency for many plugins

  -- Telescope
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup{}
      -- Telescope mappings are defined below globally
    end
  },

  -- UI Enhancements
  { "kyazdani42/nvim-web-devicons" }, -- For icons
  { "ojroques/nvim-hardline",
    config = function()
      require('hardline').setup {}
    end
  },

  -- Git
  { "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup {}
    end
  },
  { "tpope/vim-fugitive" },

  -- Language Specific
  { "rust-lang/rust.vim", lazy = true }, -- Keep for filetype detection, but rust-tools handles most
  {
    "simrat39/rust-tools.nvim",
    ft = { "rust", "rs" },
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      local rt = require("rust-tools")
      rt.setup({
        server = {
          on_attach = on_attach, -- Use our global on_attach for rust_analyzer
          -- You can add other rust-analyzer specific settings here if needed
          settings = {
            -- rust-analyzer specific settings
            ["rust-analyzer"] = {
              -- enable clippy on save
              checkOnSave = {
                command = "clippy"
              },
              -- other settings...
            }
          }
        },
        -- dap = { ... } -- DAP configuration if you want debugging
      })
    end,
  },

  -- Note: For Python formatting, ruff-lsp is now configured.
  -- For C/C++, clangd (with clang-format) will be used via LSP.

})
-- g['onedark_style'] = 'warmer'
-- g['newpaper_style'] = 'white'

-------------------- OPTIONS -------------------------------
opt.completeopt = {'menuone', 'noinsert', 'noselect'}  -- Completion options (for deoplete)
opt.clipboard = "unnamedplus"
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
map('i', '<S-Tab>', 'pumvisible() ? "\\\\<C-p>" : "\\\\<S-Tab>"', {expr = true, silent = true})
map('i', '<Tab>', 'pumvisible() ? "\\\\<C-n>" : "\\\\<Tab>"', {expr = true, silent = true})

map('n', '<C-l>', '<cmd>noh<CR>')    -- Clear highlights
map('n', '<leader>o', 'm`o<Esc>``')  -- Insert a newline in normal mode

-------------------- TREE-SITTER ---------------------------
-- Setup moved to lazy.nvim config for nvim-treesitter

-------------------- PRETTY-NEOVIM ---------------------------
-- All plugin setup calls (e.g., require('onenord').setup)
-- have been moved to their respective config blocks in lazy.nvim setup.
-- The colorscheme is also set in the onenord config.
-- vim.cmd[[colorscheme onenord]] -- This will be handled by onenord's config or can be explicitly set there.

-------------------- LSP -----------------------------------
-- LSP setup and mappings have been moved to the lazy.nvim config for nvim-lspconfig
-- and the on_attach function.

-------------------- Telescope ---------------------------
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>')
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>')
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>')

-------------------- COMMANDS ------------------------------
cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'  -- disabled in visual mode
-- cmd 'autocmd BufWritePre *.py execute \'\':Black\'\'' -- Replaced by ruff-lsp format-on-save
-- cmd 'autocmd FileType c,cpp ClangFormatAutoEnable' -- Replaced by clangd + LSP formatting
