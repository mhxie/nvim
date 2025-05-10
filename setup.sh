#!/usr/bin/env bash

# set -e # Exit immediately if a command exits with a non-zero status. Often good, but for uninstall, we might want to try all.
# set -u # Treat unset variables as an error when substituting. Consider enabling after testing.
set -o pipefail # Return value of a pipeline is the value of the last command to exit with a non-zero status

# --- Configuration ---
PYTHON_PACKAGES="python-lsp-server[all] ruff-lsp"
GO_BINARIES=("gopls" "goimports")
GO_MODULES=("golang.org/x/tools/gopls@latest" "golang.org/x/tools/cmd/goimports@latest")
RUST_COMPONENTS=("rust-analyzer" "rustfmt" "clippy")
CPP_APT_PACKAGES="clangd clang-format"
CPP_DNF_PACKAGES="clang clang-tools-extra" # clang-tools-extra usually provides clangd
CPP_YUM_PACKAGES="clang" # clangd might be in clang-tools-extra or a llvm-toolset for older Amazon Linux
CPP_BREW_PACKAGE="llvm" # Provides clangd and clang-format

# --- Helper Functions ---
info() {
    echo -e "\033[32m[INFO] $1\033[0m"
}

warn() {
    echo -e "\033[33m[WARN] $1\033[0m"
}

error() {
    echo -e "\033[31m[ERROR] $1\033[0m" >&2
}

# --- OS Detection ---
OS_NAME=$(uname -s)
LINUX_ID=""
LINUX_PRETTY_NAME=""

if [ "$OS_NAME" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        LINUX_ID=$ID
        LINUX_PRETTY_NAME=$PRETTY_NAME
    elif type lsb_release >/dev/null 2>&1; then
        LINUX_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        LINUX_PRETTY_NAME=$(lsb_release -sd)
    else
        LINUX_ID="unknown"
        LINUX_PRETTY_NAME="Unknown Linux"
    fi
fi

# --- Prerequisite Checks & Path Info ---
check_toolchain_installed() {
    local tool_name="$1"
    local command_to_check="$2"
    local install_url="$3"
    local proceed=true

    if ! command -v "$command_to_check" >/dev/null 2>&1; then
        error "Core toolchain '$tool_name' (command: '$command_to_check') not found or not in PATH."
        error "Please install it using its official method (e.g., from $install_url) and ensure it's correctly configured for your shell."
        error "The official installer usually handles PATH setup for your shell."
        proceed=false
    fi
    echo "$proceed"
}

get_go_bin_dir() {
    local go_bin_dir
    if [[ -n "$(go env GOBIN)" ]]; then
        go_bin_dir="$(go env GOBIN)"
    elif [[ -n "$(go env GOPATH)" ]]; then
        go_bin_dir="$(go env GOPATH)/bin"
    else
        go_bin_dir="$HOME/go/bin"
    fi
    echo "$go_bin_dir"
}

# --- Installation Functions ---
install_rust_tools() {
    info "Installing Rust tools (${RUST_COMPONENTS[*]})..."
    rustup component add "${RUST_COMPONENTS[@]}"
    info "Rust tools installation attempted."
}

install_go_tools() {
    info "Installing Go tools (${GO_BINARIES[*]})..."
    local go_bin_dir
    go_bin_dir=$(get_go_bin_dir)
    info "Go tools will be installed to: $go_bin_dir. Ensure this is in your PATH."
    for module in "${GO_MODULES[@]}"; do
            go install "$module"
    done
    info "Go tools installation attempted."
}

install_python_tools() {
    info "Installing Python tools ($PYTHON_PACKAGES)..."
    pip3 install --user $PYTHON_PACKAGES
    info "Python tools installation attempted. Ensure '~/.local/bin' is in your PATH."
}

install_cpp_tools_ubuntu() {
    info "Installing C/C++ tools ($CPP_APT_PACKAGES) for Ubuntu/Debian..."
    sudo apt-get update && sudo apt-get install -y $CPP_APT_PACKAGES
    info "C/C++ tools installation attempted for Ubuntu/Debian."
}

install_cpp_tools_amazon_linux() {
    info "Installing C/C++ tools for Amazon Linux..."
    if command -v dnf >/dev/null 2>&1; then # Amazon Linux 2023+
        info "Using dnf to install $CPP_DNF_PACKAGES."
        sudo dnf install -y $CPP_DNF_PACKAGES
    elif command -v yum >/dev/null 2>&1; then # Amazon Linux 2
        info "Using yum to install $CPP_YUM_PACKAGES."
        sudo yum install -y $CPP_YUM_PACKAGES
        warn "For Amazon Linux 2, clangd might require installing clang-tools-extra or a specific llvm toolset via amazon-linux-extras if not included with 'clang'."
    else
        error "Neither dnf nor yum found on Amazon Linux. Cannot install C/C++ tools automatically."
    fi
    info "C/C++ tools installation attempted for Amazon Linux."
}

install_cpp_tools_macos() {
    info "Installing C/C++ tools ($CPP_BREW_PACKAGE for clangd, clang-format) for macOS..."
    brew install $CPP_BREW_PACKAGE
    info "LLVM ($CPP_BREW_PACKAGE) installation attempted via Homebrew."
    warn "You MIGHT need to add Homebrew's LLVM to your PATH for it to be prioritized."
    warn "If you find that the system clang or an older version is still being used, try adding the following to your shell configuration file:"
    local brew_prefix_llvm
    brew_prefix_llvm=$(brew --prefix llvm)
    warn "  For bash (e.g., in ~/.bash_profile or ~/.bashrc):"
    warn "    export PATH=\"$brew_prefix_llvm/bin:\$PATH\""
    warn "  For zsh (e.g., in ~/.zshrc):"
    warn "    export PATH=\"$brew_prefix_llvm/bin:\$PATH\""
    warn "  For fish (e.g., in ~/.config/fish/config.fish):"
    warn "    fish_add_path \"$brew_prefix_llvm/bin\""
    warn "After adding, source the file (e.g., 'source ~/.zshrc') or open a new terminal."
}

# --- Uninstallation Functions ---

uninstall_rust_tools() {
    info "Uninstalling Rust tools (${RUST_COMPONENTS[*]})..."
    if command -v rustup >/dev/null 2>&1; then
        rustup component remove "${RUST_COMPONENTS[@]}"
        info "Rust tools uninstallation attempted."
    else
        warn "rustup not found. Cannot uninstall Rust tools automatically."
    fi
}

uninstall_go_tools() {
    info "Uninstalling Go tools (${GO_BINARIES[*]})..."
    if command -v go >/dev/null 2>&1; then
        local go_bin_dir
        go_bin_dir=$(get_go_bin_dir)
        for binary in "${GO_BINARIES[@]}"; do
            if [ -f "$go_bin_dir/$binary" ]; then
                info "Removing $go_bin_dir/$binary..."
                rm -f "$go_bin_dir/$binary"
            else
                warn "Go binary $go_bin_dir/$binary not found. Skipping."
            fi
        done
        info "Go tools uninstallation attempted."
    else
        warn "Go not found. Cannot uninstall Go tools automatically."
    fi
}

uninstall_python_tools() {
    info "Uninstalling Python tools ($PYTHON_PACKAGES)..."
    if command -v pip3 >/dev/null 2>&1; then
        pip3 uninstall -y $PYTHON_PACKAGES
        info "Python tools uninstallation attempted."
    else
        warn "pip3 not found. Cannot uninstall Python tools automatically."
    fi
}

uninstall_cpp_tools_ubuntu() {
    info "Uninstalling C/C++ tools ($CPP_APT_PACKAGES) for Ubuntu/Debian..."
    sudo apt-get remove -y $CPP_APT_PACKAGES && sudo apt-get autoremove -y
    info "C/C++ tools uninstallation attempted for Ubuntu/Debian."
}

uninstall_cpp_tools_amazon_linux() {
    info "Uninstalling C/C++ tools for Amazon Linux..."
    if command -v dnf >/dev/null 2>&1; then
        info "Using dnf to remove $CPP_DNF_PACKAGES."
        sudo dnf remove -y $CPP_DNF_PACKAGES
    elif command -v yum >/dev/null 2>&1; then
        info "Using yum to remove $CPP_YUM_PACKAGES."
        sudo yum remove -y $CPP_YUM_PACKAGES
        warn "If other LLVM components like clang-tools-extra were installed separately on Amazon Linux 2, they may need manual removal."
    else
        error "Neither dnf nor yum found on Amazon Linux. Cannot uninstall C/C++ tools automatically."
    fi
    info "C/C++ tools uninstallation attempted for Amazon Linux."
}

uninstall_cpp_tools_macos() {
    info "Uninstalling C/C++ tools ($CPP_BREW_PACKAGE) for macOS..."
    if command -v brew >/dev/null 2>&1; then
        brew uninstall $CPP_BREW_PACKAGE
        info "LLVM ($CPP_BREW_PACKAGE) uninstallation attempted via Homebrew."
        warn "If you manually added llvm to your PATH, you might want to remove those lines from your shell's rc file."
    else
        warn "Homebrew not found. Cannot uninstall $CPP_BREW_PACKAGE automatically."
    fi
}

# --- Main Logic ---
MODE="install"
if [[ "$1" == "--remove" || "$1" == "uninstall" ]]; then
    MODE="uninstall"
fi

info "Detected OS: $OS_NAME, Linux ID: ${LINUX_ID:-N/A}, Pretty Name: ${LINUX_PRETTY_NAME:-N/A}"
info "Script mode: $MODE"

# --- Prerequisite Toolchain Checks (Run for both install and relevant uninstall operations) ---
proceed_rust=true
proceed_go=true
proceed_python=true
proceed_cpp_macos=true # Specific to macOS brew for C++

if [[ "$MODE" == "install" || ( "$MODE" == "uninstall" && "$(echo "${RUST_COMPONENTS[@]}" | wc -w)" -gt 0 ) ]]; then
    proceed_rust=$(check_toolchain_installed "Rust (rustup)" "rustup" "https://www.rust-lang.org/tools/install")
fi
if [[ "$MODE" == "install" || ( "$MODE" == "uninstall" && "$(echo "${GO_BINARIES[@]}" | wc -w)" -gt 0 ) ]]; then
    proceed_go=$(check_toolchain_installed "Go" "go" "https://golang.org/doc/install")
fi
if [[ "$MODE" == "install" || ( "$MODE" == "uninstall" && -n "$PYTHON_PACKAGES" ) ]]; then
    proceed_python=$(check_toolchain_installed "Python3 (pip3)" "pip3" "https://www.python.org/downloads/")
fi
if [ "$OS_NAME" = "Darwin" ] && [[ "$MODE" == "install" || ( "$MODE" == "uninstall" && -n "$CPP_BREW_PACKAGE" ) ]]; then
    proceed_cpp_macos=$(check_toolchain_installed "Homebrew" "brew" "https://brew.sh/")
fi

# Check if any core toolchain is missing for install mode, and exit if so.
if [ "$MODE" = "install" ]; then
    if ! $proceed_rust || ! $proceed_go || ! $proceed_python || ( [ "$OS_NAME" = "Darwin" ] && ! $proceed_cpp_macos ); then
        error "One or more core toolchains are missing. Please install them and re-run the script."
        info "---------------------------------------------------------------------"
        info "Script finished with errors due to missing prerequisites."
        info "---------------------------------------------------------------------"
        exit 1
    fi
fi


if [ "$MODE" = "install" ]; then
    info "Starting linter and formatter INSTALLATION script..."
    info "This script will attempt to install tools using system package managers and language-specific toolchains."
    info "You might be prompted for sudo password for some installations."

    if $proceed_rust; then install_rust_tools; fi
    if $proceed_go; then install_go_tools; fi
    if $proceed_python; then install_python_tools; fi

    if [ "$OS_NAME" = "Darwin" ]; then
        if $proceed_cpp_macos; then install_cpp_tools_macos; fi
    elif [ "$OS_NAME" = "Linux" ]; then
        if [[ "$LINUX_ID" = "ubuntu" || "$LINUX_ID" = "debian" ]]; then
            install_cpp_tools_ubuntu
        elif [ "$LINUX_ID" = "amzn" ]; then
            install_cpp_tools_amazon_linux
        else
            error "Unsupported Linux distribution for C/C++ tools: ${LINUX_PRETTY_NAME:-$LINUX_ID}. Please install clangd and clang-format manually."
        fi
    else
        error "Unsupported OS for C/C++ tools: $OS_NAME. Please install clangd and clang-format manually."
    fi
    info "INSTALLATION process attempted."

elif [ "$MODE" = "uninstall" ]; then
    info "Starting linter and formatter UNINSTALLATION script..."

    if $proceed_rust; then uninstall_rust_tools; else warn "Skipping Rust tools uninstall (rustup not found)."; fi
    if $proceed_go; then uninstall_go_tools; else warn "Skipping Go tools uninstall (go not found)."; fi
    if $proceed_python; then uninstall_python_tools; else warn "Skipping Python tools uninstall (pip3 not found)."; fi

    if [ "$OS_NAME" = "Darwin" ]; then
        if $proceed_cpp_macos; then uninstall_cpp_tools_macos; else warn "Skipping C/C++ (llvm) tools uninstall (brew not found)."; fi
    elif [ "$OS_NAME" = "Linux" ]; then
        if [[ "$LINUX_ID" = "ubuntu" || "$LINUX_ID" = "debian" ]]; then
            uninstall_cpp_tools_ubuntu
        elif [ "$LINUX_ID" = "amzn" ]; then
            uninstall_cpp_tools_amazon_linux
        else
            error "Unsupported Linux distribution for C/C++ tools uninstallation: ${LINUX_PRETTY_NAME:-$LINUX_ID}. Please uninstall relevant packages manually."
        fi
    else
        error "Unsupported OS for C/C++ tools uninstallation: $OS_NAME. Please uninstall relevant packages manually."
    fi
    info "UNINSTALLATION process attempted."
fi

info "---------------------------------------------------------------------"
info "Script finished."
info "Please review any error or warning messages above."
info "If installing, ensure all installed binaries are in your system's PATH."
info "You may need to restart your terminal session or Neovim for changes to take effect."
info "---------------------------------------------------------------------" 