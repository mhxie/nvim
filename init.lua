-- Lua bytecode cache (Neovim 0.9+). Biggest single startup win on warm
-- runs — cached compiled chunks bypass the parser for every required file.
vim.loader.enable()

-- Disable built-in runtime plugins we don't use. Each `loaded_*` flag
-- skips sourcing the corresponding `runtime/plugin/*.vim` at startup.
for _, name in ipairs({
  "gzip", "tar", "tarPlugin", "zip", "zipPlugin",
  "netrwPlugin", -- file browser; superseded by yazi
  "tutor",
}) do
  vim.g["loaded_" .. name] = 1
end

-- Disable unused language hosts ($EDITOR providers). We don't author
-- nvim plugins in perl / ruby / node, so suppress the host probes that
-- otherwise show up in :checkhealth.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

require("options")
require("keymaps")
require("plugins")
require("lsp")
