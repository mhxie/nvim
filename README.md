## Personal Neovim Configuration for [Your Name/Handle]

Welcome to my personal Neovim setup! This configuration is designed for a productive development experience in C/C++, Rust, Python, and Go.

##  Prerequisites

Before you begin, make sure you have the following installed:

1.  **Neovim (v0.11.1 or later)**:
    *   From source (recommended for specific version):
        ```bash
        git clone https://github.com/neovim/neovim.git && cd neovim
        git checkout v0.11.1 # Or your desired version
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install
        ```
    *   Or, via package manager (e.g., `sudo apt-get install neovim` on Debian/Ubuntu).

2.  **Git**: Essential for managing plugins and this configuration.

3.  **Core Language Toolchains**: These are fundamental for the languages you plan to use. The `setup.sh` script (see below) relies on these being installed and in your `PATH`.
    *   **Rust**: Install via [rustup](https://www.rust-lang.org/tools/install) (`rustup`, `cargo`).
    *   **Go**: Install the [Go toolchain](https://golang.org/doc/install) (`go` command).
    *   **Python**: Install [Python 3](https://www.python.org/downloads/) (`python3`, `pip3`).
    *   **macOS Users**: Install [Homebrew](https://brew.sh/) if you intend to use C/C++ tools.

4.  **Plugin Dependencies**:
    *   For `deoplete.nvim` (autocompletion):
        ```bash
        pip3 install --user pynvim
        ```
        (Run `:UpdateRemotePlugins` in Neovim after installation if prompted).
    *   For `telescope.nvim` (fuzzy finding):
        *   `ripgrep` (rg): For searching. ([Installation Guide](https://github.com/BurntSushi/ripgrep#installation))
        *   `fd` (fd-find): For finding files. ([Installation Guide](https://github.com/sharkdp/fd#installation))

## Installation Steps

1.  **Clone this Configuration**:
    ```bash
    cd ~/.config
    git clone https://github.com/mhxie/nvim.git # Replace with your repo URL if forked
    ```

2.  **Install Linters, Formatters, and Language Servers**:
    This setup uses a helper script to install necessary development tools. Navigate to the config directory and run:
    ```bash
    cd ~/.config/nvim
    chmod +x setup.sh
    ./setup.sh install
    ```
    This script supports Linux (Ubuntu/Debian, Amazon Linux) and macOS. It will attempt to install:
    *   Rust tools: `rust-analyzer`, `rustfmt`, `clippy`
    *   C/C++ tools: `clangd`, `clang-format`
    *   Python tools: `python-lsp-server`, `ruff-lsp` (provides `ruff` LSP)
    *   Go tools: `gopls`, `goimports`

    To **uninstall** these tools later, run `./setup.sh uninstall`.
    *Review the script's output for any errors or PATH adjustments needed.*

3.  **Launch Neovim**:
    ```bash
    nvim
    ```
    `lazy.nvim` (our plugin manager) will automatically bootstrap itself and install all configured plugins on the first run. You might need to restart Neovim after the initial plugin installation.

## Helpful Neovim Commands

*   `:Lazy sync`: Synchronizes plugins (installs, updates, cleans).
*   `:Lazy install`: Installs any missing plugins.
*   `:Lazy update`: Updates installed plugins.
*   `:Lazy clean`: Removes disabled or unused plugins.
*   `:checkhealth`: Troubleshoots loading issues (useful for `nvim-treesitter`, LSPs).
*   `:TSUpdate`: Manually update all Treesitter parsers (if needed).
*   `:TSUninstall all`: Uninstall all Treesitter parsers.

## Configured Language Tools (for reference)

The `setup.sh` script handles installation, but here's a quick overview of the primary tools configured:

*   **Rust**: `rust-analyzer` (via `rust-tools.nvim`), `rustfmt`, `clippy`
*   **C/C++**: `clangd`, `clang-format`
*   **Python**: `pylsp`, `ruff` (LSP via `ruff-lsp` package)
*   **Go**: `gopls`, `goimports`

## TODO

*   More language support (YAML, TOML, HTML ...)
*   Add code analysis tools (e.g., Facebook Infer)

## References

*   [Neovim Official](https://github.com/neovim/neovim)
*   [My Neovim Init Notes (Example Link)](https://oroques.dev/notes/neovim-init/) (Update if you have one)
*   [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)
*   [Deoplete.nvim](https://github.com/Shougo/deoplete.nvim)

---
Happy Coding!
