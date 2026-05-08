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

  -- Completion: blink.cmp (replaces archived nvim-cmp + cmp-* sources).
  -- Versioned tag downloads a prebuilt Rust fuzzy matcher; no local rustc
  -- needed. Snippets come from `friendly-snippets`.
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = { preset = 'default' },        -- <C-Space> open, <CR> accept, <C-p>/<C-n> + <Tab>/<S-Tab> nav, <C-b>/<C-f> scroll docs
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
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
    event = { "BufReadPost", "BufNewFile" }, -- defer until a buffer exists
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
    event = { "BufReadPre", "BufNewFile" }, -- gutter signs need a real buffer
    config = function()
      require('gitsigns').setup {}
    end
  },
  -- Fugitive is purely command-driven — load only when invoked.
  { "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiff", "Gdiffsplit", "Gvdiffsplit",
            "Gread", "Gwrite", "Gedit", "Gblame", "Gstatus", "Glog" },
  },

  -- GitHub Copilot — only matters once you start typing.
  { "github/copilot.vim",
    event = "InsertEnter",
  },

  -- Rust: rustaceanvim handles filetype detection, LSP wiring, and Rust
  -- niceties (cargo-style mappings, expand macros, etc.) — replaces both
  -- the archived rust-tools.nvim and the older rust.vim ftplugin.
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- plugin loads itself on Rust filetypes
    ft = { "rust" },
  },

}) 