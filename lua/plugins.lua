-- Ensure lazy.nvim is installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
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

require("lazy").setup({
  -- Core plugins
  { "folke/lazy.nvim", version = "*" }, -- lazy.nvim manages itself

  -- Mason for LSP management (org moved from williamboman -> mason-org)
  { "mason-org/mason.nvim" },
  { "mason-org/mason-lspconfig.nvim" },

  -- Colorschemes
  { "rmehri01/onenord.nvim",
    lazy = false, -- Load theme on startup
    priority = 1000, -- Ensure it's loaded first
    config = function()
      require('onenord').setup {}
      vim.cmd[[colorscheme onenord]]
    end
  },

  -- Completion: nvim-cmp
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      -- Optional: Add snippet engine like LuaSnip and its cmp source
      -- 'L3MON4D3/LuaSnip',
      -- 'saadparwaiz1/cmp_luasnip', 
    },
    config = function()
      local cmp = require'cmp'
      local luasnip = nil -- Placeholder, will be set if LuaSnip is added
      -- local luasnip_status_ok, luasnip_module = pcall(require, "luasnip")
      -- if luasnip_status_ok then luasnip = luasnip_module end

      cmp.setup({
        snippet = {
          expand = function(args)
            if luasnip then
              luasnip.lsp_expand(args.body)
            end
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set to false to only confirm explicitly selected items.
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip and luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }), -- i for insert mode, s for select mode (if any)
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip and luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
          -- { name = 'luasnip' }, -- if using LuaSnip
        })
      })
    end
  },

  -- Formatting: conform.nvim
  {
    'stevearc/conform.nvim',
    event = { "BufWritePre" }, -- Or "VeryLazy" and setup autocmd manually
    cmd = { "ConformInfo" },
    opts = {
      notify_on_error = true,
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true, -- Fallback to LSP formatting if no formatter defined
      },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format", "isort" }, -- ruff can format and sort imports
        c = { "clang_format" },
        cpp = { "clang_format" },
        rust = { "rustfmt" },
        -- Add more formatters as needed
        -- javascript = { "prettier" },
        -- typescript = { "prettier" },
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)
      -- Optional: Add a command to format explicitly
      vim.api.nvim_create_user_command("Format", function(args)
        require("conform").format({ async = true, lsp_fallback = true, quiet = args.quiet })
      end, { nargs = "?", complete = function() return { "quiet" } end, desc = "Format current buffer" })

      -- Optional: Keymap for formatting
      vim.keymap.set({"n", "v"}, "<leader>f", function()
          require("conform").format({ async = true, lsp_fallback = true })
      end, {desc = "Format buffer/selection"})
    end
  },

  -- Treesitter — pin to `master` (stable legacy API). The repo's default
  -- branch is now `main`, which is a partial rewrite without the legacy
  -- `nvim-treesitter.configs` module that this config depends on.
  { "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = {'c', 'cpp', 'python', 'rust', 'lua', 'go'},
        highlight = {
          enable = true,
        },
      }
    end
  },

  -- LSP Configuration (main setup will be in lsp.lua)
  { "neovim/nvim-lspconfig" }, 

  -- Utility
  { "nvim-lua/plenary.nvim" }, -- Common dependency for many plugins

  -- Telescope
  { "nvim-telescope/telescope.nvim",
    event = "VeryLazy", -- As per user suggestion
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup{}
      -- Telescope keymaps are in keymaps.lua
    end
  },

  -- UI Enhancements (org renamed from kyazdani42 -> nvim-tree)
  { "nvim-tree/nvim-web-devicons" }, -- For icons
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

  -- GitHub Copilot
  { 
    "github/copilot.vim",
  },

  -- Language Specific
  { "rust-lang/rust.vim", lazy = true },
  -- rust-tools.nvim was archived in 2023; rustaceanvim is the maintained successor.
  -- It auto-configures rust-analyzer via lspconfig — no explicit setup() needed.
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- plugin loads itself on Rust filetypes
    ft = { "rust" },
  },

}) 