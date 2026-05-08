-- LSP setup for nvim 0.11+: uses vim.lsp.config()/vim.lsp.enable() (the new
-- core API). The legacy `require('lspconfig').X.setup{}` framework is
-- deprecated and slated for removal in nvim-lspconfig v3.
--
-- Wiring:
--   1. vim.lsp.config('*',  ...)  -> defaults applied to every server
--   2. vim.lsp.config('<srv>', ...) -> per-server overrides
--   3. mason-lspconfig.setup{ automatic_enable = ... } enables installed
--      servers via vim.lsp.enable(), which actually starts them on
--      matching filetypes.

local ok_blink, blink_cmp = pcall(require, "blink.cmp")

-- Buffer-attach hook: keymaps + omnifunc.
local on_attach = function(client, bufnr)
  if not (type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr)) then
    return
  end

  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

  local map_opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', 'gd',          vim.lsp.buf.definition,     vim.tbl_extend('force', map_opts, { desc = "Go to definition" }))
  vim.keymap.set('n', 'K',           vim.lsp.buf.hover,          vim.tbl_extend('force', map_opts, { desc = "Hover documentation" }))
  vim.keymap.set('n', 'gi',          vim.lsp.buf.implementation, vim.tbl_extend('force', map_opts, { desc = "Go to implementation" }))
  vim.keymap.set('n', '<leader>rn',  vim.lsp.buf.rename,         vim.tbl_extend('force', map_opts, { desc = "Rename" }))
  vim.keymap.set({'n','v'}, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', map_opts, { desc = "Code action" }))
  vim.keymap.set('n', 'gr',          vim.lsp.buf.references,     vim.tbl_extend('force', map_opts, { desc = "Go to references" }))
end

-- Capabilities: blink.cmp extends LSP capabilities (snippet support, etc.)
-- when available; otherwise fall back to stock.
local capabilities = vim.lsp.protocol.make_client_capabilities()
if ok_blink then
  capabilities = blink_cmp.get_lsp_capabilities(capabilities)
end

-- Default config applied to all servers.
vim.lsp.config('*', {
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Per-server overrides. Server defaults (cmd, filetypes, root markers) are
-- supplied by nvim-lspconfig's built-in `lsp/<server>.lua` files, picked up
-- automatically from its runtime path.
vim.lsp.config('ruff', {
  init_options = {
    settings = {
      format = { excludedFiles = {} },
    },
  },
})

-- Mason: package manager for LSP servers / formatters / DAP.
require("mason").setup()

-- Servers to install via mason. rust_analyzer is excluded from
-- mason-lspconfig's auto-enable list because rustaceanvim owns the Rust
-- LSP client lifecycle (double-enabling spawns two clients).
require("mason-lspconfig").setup({
  ensure_installed = { "clangd", "ruff", "gopls", "rust_analyzer" },
  automatic_enable = { exclude = { "rust_analyzer" } },
})

-- Rustaceanvim (Rust): owns rust-analyzer. Configuration must be set on
-- vim.g BEFORE the plugin loads.
vim.g.rustaceanvim = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
    default_settings = {
      ["rust-analyzer"] = {
        -- Modern rust-analyzer expects these as separate keys.
        -- The legacy `checkOnSave = { command = "clippy" }` map form
        -- now fails schema validation.
        checkOnSave = true,
        check = { command = "clippy" },
      },
    },
  },
}
