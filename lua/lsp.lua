local lspconfig = require('lspconfig')
local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_ok then
  cmp_nvim_lsp = nil -- Ensure it's nil if pcall failed, so the later check works as intended
end

-- Custom on_attach function
local on_attach = function(client, bufnr)
  -- Check if bufnr is valid
  if not (type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr)) then
    vim.notify(
      string.format("LSP on_attach: Invalid bufnr. Client: %s, Type: %s, Value: %s", client.name, type(bufnr), tostring(bufnr)),
      vim.log.levels.WARN
    )
    return
  end

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      vim.notify(
        string.format("LSP on_attach (scheduled): bufnr %s became invalid for client %s. Aborting setup.",
                      tostring(bufnr), client.name),
        vim.log.levels.WARN
      )
      return
    end

    vim.notify(
        string.format("LSP on_attach (scheduled): Client: %s, bufnr: %s. Setting omnifunc and keymaps.",
                      client.name, tostring(bufnr)),
        vim.log.levels.INFO
    )
    -- Enable completion triggered by <c-x><c-o> for all LSPs
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Keymaps (example from user, extend as needed)
    local map_opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', map_opts, { desc = "Go to definition" }))
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', map_opts, { desc = "Hover documentation" }))
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', map_opts, { desc = "Go to implementation" }))
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', map_opts, { desc = "Rename" }))
    vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', map_opts, { desc = "Code action" }))
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', map_opts, { desc = "Go to references" }))
    -- Use <leader>e for diagnostics as defined in keymaps.lua, or define here if preferred for LSP-specific diagnostics
    -- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, vim.tbl_extend('force', map_opts, { desc = "Show line diagnostics" }))
  end)
end

-- Setup mason
require("mason").setup()

-- Define a list of servers to ensure are installed
local ensure_installed_servers = { "clangd", "pylsp", "gopls", "rust_analyzer" }

require("mason-lspconfig").setup({
  ensure_installed = ensure_installed_servers,
})

-- Get capabilities for nvim-cmp (or default if not using cmp)
local capabilities = vim.lsp.protocol.make_client_capabilities()
if cmp_nvim_lsp then -- Check if cmp_nvim_lsp was successfully required
 capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
else
 vim.notify("nvim-cmp capabilities not loaded for LSP. Consider installing nvim-cmp.", vim.log.levels.INFO)
end


-- Configure servers
local nvim_python_venv = vim.fn.expand('$HOME') .. '/.config/nvim/venvs/nvim-python-tools'

-- C++: clangd setup
lspconfig.clangd.setup { 
  on_attach = on_attach,
  capabilities = capabilities
}

-- Python: pylsp setup (optional, ruff_lsp can handle linting/formatting)
-- lspconfig.pylsp.setup { 
--   on_attach = on_attach, 
--   cmd = { nvim_python_venv .. '/bin/pylsp' },
--   capabilities = capabilities
-- }

-- Python: ruff_lsp setup (for linting and formatting)
-- Name changed from ruff_lsp to ruff
lspconfig.ruff.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {
    settings = {
      -- Any specific ruff settings, e.g.:
      -- lint = { select = { "E", "F", "W", "I", "N", "D" } },
      format = { excludedFiles = {} } -- Example, ensure it formats by default
    }
  }
}

-- Go: gopls setup
lspconfig.gopls.setup { 
  on_attach = on_attach,
  capabilities = capabilities
}

-- Rust: rust-tools.nvim setup
local rt = require("rust-tools")
rt.setup({
  server = {
    on_attach = on_attach, -- Use the global on_attach
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy"
        },
      }
    }
  },
  -- dap = { ... } -- DAP configuration if you want debugging
})

-- Ensure other LSPs use the on_attach and capabilities as well
-- Example for lua_ls (if you add it via mason)
-- lspconfig.lua_ls.setup {
--  on_attach = on_attach,
--  capabilities = capabilities,
--  settings = {
--    Lua = {
--      diagnostics = { globals = { 'vim' } }
--    }
--  }
-- } 