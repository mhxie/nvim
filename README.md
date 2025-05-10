## Personal Neovim Configuration for mhxie

Welcome to my personal Neovim setup! This configuration is designed for a productive development experience in C/C++, Rust, Python, and Go, featuring modern tooling for completion, LSP, and formatting.

## Prerequisites

Before you begin, make sure you have the following installed:

1.  **Neovim (v0.10.0 or later recommended)**:
    *   Check the [Neovim releases](https://github.com/neovim/neovim/releases) page for installation instructions for your OS. Using a recent version is crucial for compatibility with modern plugins.

2.  **Git**: Essential for managing plugins and this configuration.

3.  **Core Language Toolchains**: These are fundamental for the languages you plan to use. The `setup.sh` script (see below) relies on these being installed and in your `PATH`.
    *   **Rust**: Install via [rustup](https://www.rust-lang.org/tools/install) (`rustup`, `cargo`). This is also used by `setup.sh` to install `stylua`.
    *   **Go**: Install the [Go toolchain](https://golang.org/doc/install) (`go` command).
    *   **Python**: Install [Python 3](https://www.python.org/downloads/) (`python3`, `pip3`).
    *   **macOS Users**: Install [Homebrew](https://brew.sh/) if you intend to use C/C++ tools or other packages conveniently.

4.  **Node.js (LTS recommended)**: Required for `github/copilot.vim`. Install from [nodejs.org](https://nodejs.org/) or via a version manager like `nvm`. The `setup.sh` script can also attempt to install this.

5.  **Build Tools (for some plugins/LSPs)**:
    *   A C compiler (like `gcc` or `clang`) is often needed for building Treesitter parsers or other native extensions for plugins.
    *   `make`, `cmake` might be needed if building Neovim from source or for certain plugins.

6.  **Formatter Dependencies**:
    *   This setup uses `conform.nvim` which relies on external formatter executables. The `setup.sh` script aims to install:
        *   `stylua` (for Lua)
        *   `ruff` (for Python formatting and linting)
        *   `isort` (for Python import sorting, works with `ruff`)
        *   `clang-format` (for C/C++)
        *   `rustfmt` (for Rust)
    *   Ensure these are installable on your system (e.g., `cargo` for Rust-based tools, `pip` for Python tools).

7.  **For `telescope.nvim` (fuzzy finding)**:
    *   `ripgrep` (rg): For searching. ([Installation Guide](https://github.com/BurntSushi/ripgrep#installation))
    *   `fd` (fd-find): For finding files. ([Installation Guide](https://github.com/sharkdp/fd#installation))
    *   These are highly recommended for Telescope to function optimally.

## Installation Steps

1.  **Clone this Configuration**:
    ```bash
    # Backup your existing nvim config if you have one:
    # mv ~/.config/nvim ~/.config/nvim.bak
    # mv ~/.local/share/nvim ~/.local/share/nvim.bak
    # mv ~/.local/state/nvim ~/.local/state/nvim.bak
    # mv ~/.cache/nvim ~/.cache/nvim.bak

    git clone https://github.com/mhxie/nvim.git ~/.config/nvim
    ```

2.  **Install Linters, Formatters, and Language Servers**:
    This setup uses a helper script (`setup.sh`) to install necessary development tools. Navigate to the config directory and run:
    ```bash
    cd ~/.config/nvim
    chmod +x setup.sh
    ./setup.sh install
    ```
    This script supports Linux (Ubuntu/Debian, Amazon Linux) and macOS. It will attempt to install:
    *   **Rust tools**: `rust-analyzer`, `rustfmt`, `clippy`, `stylua` (via cargo)
    *   **C/C++ tools**: `clangd`, `clang-format`
    *   **Python tools**: `ruff`, `isort` (into a venv: `~/.config/nvim/venvs/nvim-python-tools`)
    *   **Go tools**: `gopls`, `goimports`
    *   **Node.js**: If not already installed.

    To **uninstall** these tools later, run `./setup.sh uninstall`.
    *Review the script\'s output for any errors or PATH adjustments needed. You might need to source your shell config or open a new terminal after running the script.*

3.  **Launch Neovim**:
    ```bash
    nvim
    ```
    `lazy.nvim` (our plugin manager) will automatically bootstrap itself and install all configured plugins on the first run. You might need to restart Neovim after the initial plugin installation.
    *   After installing plugins, run `:Copilot setup` in Neovim to authorize the GitHub Copilot plugin if you use it.
    *   Run `:checkhealth` to see if there are any issues, especially with `nvim-treesitter` or LSP configurations.

## Helpful Neovim Commands

*   `:Lazy` or `:Lazy sync`: Opens the lazy.nvim UI. Synchronizes plugins (installs, updates, cleans).
*   `:Mason`: Opens the Mason UI to manage LSP servers, DAPs, linters, and formatters.
*   `:ConformInfo`: Shows information about available formatters for the current buffer.
*   `:Format`: Manually formats the current buffer using `conform.nvim`.
*   `:Copilot setup`: To authorize and configure GitHub Copilot.
*   `:checkhealth`: Troubleshoots loading issues (useful for `nvim-treesitter`, LSPs, general setup).
*   `:TSUpdate`: Manually update all Treesitter parsers (if needed).

## Configured Language Tools & Key Plugins

This setup is modular, with configurations in `lua/options.lua`, `lua/keymaps.lua`, `lua/plugins.lua`, and `lua/lsp.lua`.

*   **Plugin Manager**: `folke/lazy.nvim`
*   **Completion**: `hrsh7th/nvim-cmp` (with sources for LSP, buffer, path)
*   **Formatting**: `stevearc/conform.nvim` (handles `stylua`, `ruff format`, `isort`, `clang-format`, `rustfmt`)
*   **LSP Management**: `williamboman/mason.nvim` and `williamboman/mason-lspconfig.nvim`
*   **Key LSPs Configured**:
    *   **Rust**: `rust-analyzer` (via `rust-tools.nvim`)
    *   **C/C++**: `clangd`
    *   **Python**: `ruff` (provides LSP features, linting, and formatting)
    *   **Go**: `gopls`
*   **Fuzzy Finding**: `nvim-telescope/telescope.nvim`
*   **Treesitter**: `nvim-treesitter/nvim-treesitter` (for syntax highlighting and more)
*   **Git Integration**: `lewis6991/gitsigns.nvim`, `tpope/vim-fugitive`
*   **GitHub Copilot**: `github/copilot.vim`

## TODO

*   More language support (YAML, TOML, HTML ...) with LSP and formatters.
*   Explore DAP (Debug Adapter Protocol) integration for debugging.
*   Add code analysis tools (e.g., linters not covered by formatters/LSPs).

## References

*   [Neovim Official](https://neovim.io/)
*   [lazy.nvim](https://github.com/folke/lazy.nvim)
*   [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
*   [conform.nvim](https://github.com/stevearc/conform.nvim)
*   [mason.nvim](https://github.com/williamboman/mason.nvim)
*   [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)

---
Happy Coding!
