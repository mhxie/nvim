#!/usr/bin/env bash

# set -e # Exit immediately if a command exits with a non-zero status. Often good, but for uninstall, we might want to try all.
# set -u # Treat unset variables as an error when substituting. Consider enabling after testing.
set -o pipefail # Return value of a pipeline is the value of the last command to exit with a non-zero status

# --- Configuration ---
PYTHON_PACKAGES="ruff isort"
GO_BINARIES=("gopls" "goimports")
GO_MODULES=("golang.org/x/tools/gopls@latest" "golang.org/x/tools/cmd/goimports@latest")
RUST_COMPONENTS=("rust-analyzer" "rustfmt" "clippy")
CPP_APT_PACKAGES="clangd clang-format"
CPP_DNF_PACKAGES="clang clang-tools-extra" # clang-tools-extra usually provides clangd
CPP_YUM_PACKAGES="clang" # clangd might be in clang-tools-extra or a llvm-toolset for older Amazon Linux
CPP_BREW_PACKAGE="llvm" # Provides clangd and clang-format

# Python Virtual Environment for Neovim tools
NVIM_PYTHON_VENV_PATH="$HOME/.config/nvim/venvs/nvim-python-tools"

# Node.js versions - consider using LTS
NODE_MAJOR_VERSION="20" # Example: For Node.js 20.x LTS

SHELL_CONFIG_MODIFIED=false # Global flag to track if shell config was changed

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

check_command_exists() {
    command -v "$1" >/dev/null 2>&1
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
    if ! command -v rustup >/dev/null 2>&1; then
        error "rustup not found. Cannot install Rust components (${RUST_COMPONENTS[*]}). Please install Rust via rustup first (https://www.rust-lang.org/tools/install)."
        return 1
    fi
    rustup component add "${RUST_COMPONENTS[@]}"
    info "Rust tools installation attempted."
}

install_stylua() {
    info "Installing stylua (Lua formatter) via cargo..."
    if ! command -v cargo >/dev/null 2>&1; then
        error "cargo (Rust's package manager) not found. Cannot install stylua. Please ensure Rust is installed correctly via rustup."
        return 1
    fi
    if cargo install stylua; then
        info "stylua installation successful."
    else
        error "stylua installation via cargo failed. Check cargo output."
        return 1
    fi
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
    info "Installing Python tools ($PYTHON_PACKAGES) into virtual environment: $NVIM_PYTHON_VENV_PATH..."

    if [ "$OS_NAME" = "Linux" ]; then
        # For Debian/Ubuntu, ensure python3-venv is available
        if [[ "$LINUX_ID" = "ubuntu" || "$LINUX_ID" = "debian" || "$LINUX_ID" = "raspbian" || "$LINUX_ID" = "linuxmint" ]]; then
            if ! dpkg -s python3-venv >/dev/null 2>&1; then
                info "python3-venv package not found. Attempting to install it..."
                sudo apt-get update && sudo apt-get install -y python3-venv
                if ! dpkg -s python3-venv >/dev/null 2>&1; then
                    error "Failed to install python3-venv. Python tools cannot be installed in a virtual environment without it."
                    error "Please install python3-venv manually (e.g., sudo apt install python3-venv) and re-run the script."
                    return 1
                fi
            fi
        fi
    fi

    # Check if python3 is available before creating venv
    if ! check_command_exists "python3"; then
        error "python3 command not found. Cannot create virtual environment. Please ensure Python 3 is installed."
        return 1
    fi

    # Create the virtual environment if it doesn't exist
    if [ ! -d "$NVIM_PYTHON_VENV_PATH/bin" ]; then
        info "Creating Python virtual environment at $NVIM_PYTHON_VENV_PATH..."
        # Remove directory if it exists but is not a venv, to avoid errors with -m venv
        if [ -d "$NVIM_PYTHON_VENV_PATH" ]; then
            rm -rf "$NVIM_PYTHON_VENV_PATH"
        fi
        python3 -m venv "$NVIM_PYTHON_VENV_PATH"
        if [ ! -f "$NVIM_PYTHON_VENV_PATH/bin/pip" ]; then
            error "Failed to create Python virtual environment. Pip executable not found in venv."
            return 1
        fi
        info "Virtual environment created successfully."
    else
        info "Virtual environment at $NVIM_PYTHON_VENV_PATH already exists."
    fi

    # Install packages into the virtual environment
    info "Installing packages using pip from the virtual environment..."
    "$NVIM_PYTHON_VENV_PATH/bin/pip" install --upgrade pip setuptools wheel # Upgrade pip first
    if ! "$NVIM_PYTHON_VENV_PATH/bin/pip" install $PYTHON_PACKAGES; then
        error "Failed to install Python packages into the virtual environment. Please check the pip output above."
        return 1
    fi

    info "Python tools ($PYTHON_PACKAGES) installation attempted in $NVIM_PYTHON_VENV_PATH."
    warn "IMPORTANT: You will need to configure Neovim to use LSPs from this virtual environment."
    warn "For example, for pylsp, the command in your Neovim LSP setup should be something like: '$NVIM_PYTHON_VENV_PATH/bin/pylsp'."
    warn "For ruff-lsp, ensure it (and ruff CLI) are found within this venv when Neovim starts the LSP: '$NVIM_PYTHON_VENV_PATH/bin/ruff' for the CLI component."
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

install_nodejs() {
    info "Installing Node.js and npm..."
    if check_command_exists "node" && check_command_exists "npm"; then
        info "Node.js and npm already seem to be installed."
        info "Node version: $(node -v), npm version: $(npm -v)"
        # Optionally, add a version check here if a minimum version is required.
        return 0
    fi

    if [ "$OS_NAME" = "Linux" ]; then
        if ! check_command_exists "curl"; then
            error "curl is required to download Node.js installation scripts but it's not installed. Please install curl first."
            return 1
        fi
        case "$LINUX_ID" in
            ubuntu|debian|raspbian|linuxmint)
                info "Setting up Node.js LTS repository for Debian/Ubuntu..."
                if ! check_command_exists "gpg"; then
                    info "gpg is not installed. Attempting to install it..."
                    sudo apt-get update && sudo apt-get install -y gpg
                    if ! check_command_exists "gpg"; then
                        error "Failed to install gpg, which is required for adding NodeSource repository. Please install gpg and try again."
                        return 1
                    fi
                fi
                curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
                echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
                sudo apt-get update
                sudo apt-get install -y nodejs
                ;;
            amzn|fedora|centos|rhel) # Amazon Linux, Fedora, CentOS, RHEL
                info "Setting up Node.js LTS repository for $LINUX_PRETTY_NAME..."
                curl -fsSL https://rpm.nodesource.com/setup_$NODE_MAJOR_VERSION.x | sudo bash -
                if command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y nodejs
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum install -y nodejs
                else
                    error "Neither dnf nor yum found on this system. Cannot install Node.js."
                    return 1
                fi
                ;;
            *)
                error "Unsupported Linux distribution for Node.js auto-installation: $LINUX_PRETTY_NAME. Please install Node.js manually (https://nodejs.org/)."
                return 1
                ;;
        esac
    elif [ "$OS_NAME" = "Darwin" ]; then
        if ! check_command_exists "brew"; then
            error "Homebrew (brew) is not installed, which is needed to install Node.js on macOS. Please install Homebrew first (https://brew.sh/)."
            return 1
        fi
        info "Installing Node.js via Homebrew..."
        brew install node
    else
        error "Unsupported OS for Node.js auto-installation: $OS_NAME. Please install Node.js manually (https://nodejs.org/)."
        return 1
    fi

    if check_command_exists "node" && check_command_exists "npm"; then
        info "Node.js installation successful."
        info "Node version: $(node -v), npm version: $(npm -v)"
    else
        error "Node.js installation failed or node/npm are not in PATH. Please check the output and install manually if needed."
        return 1
    fi
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

uninstall_stylua() {
    info "Uninstalling stylua..."
    if ! command -v cargo >/dev/null 2>&1; then
        warn "cargo not found. Cannot determine if stylua is installed via cargo or uninstall it."
        return
    fi
    # Check if stylua is installed via cargo. `cargo uninstall` exits 0 even if not found.
    # A more robust check might involve checking `cargo install --list` or `~/.cargo/bin/stylua` existence.
    if command -v stylua >/dev/null 2>&1 && [[ "$(command -v stylua)" == *"/.cargo/bin/stylua" ]]; then
        if cargo uninstall stylua; then
            info "stylua uninstallation successful."
        else
            warn "cargo uninstall stylua command failed. It might not have been installed via cargo or an error occurred."
        fi
    else
        warn "stylua not found in cargo's bin path or not installed via cargo. Skipping cargo uninstall."
        info "If you installed stylua manually, please remove it manually."
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
    info "Uninstalling Python tools by removing virtual environment: $NVIM_PYTHON_VENV_PATH..."
    if [ -d "$NVIM_PYTHON_VENV_PATH" ]; then
        rm -rf "$NVIM_PYTHON_VENV_PATH"
        info "Python virtual environment removed."
    else
        warn "Python virtual environment at $NVIM_PYTHON_VENV_PATH not found. Skipping removal."
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

uninstall_nodejs() {
    info "Uninstalling Node.js and npm..."
    if ! check_command_exists "node" && ! check_command_exists "npm"; then
        info "Node.js and npm do not seem to be installed. Skipping uninstallation."
        return 0
    fi

    if [ "$OS_NAME" = "Linux" ]; then
        case "$LINUX_ID" in
            ubuntu|debian|raspbian|linuxmint)
                info "Uninstalling Node.js from Debian/Ubuntu..."
                sudo apt-get purge -y nodejs
                sudo rm -f /etc/apt/sources.list.d/nodesource.list
                sudo rm -f /etc/apt/keyrings/nodesource.gpg
                sudo apt-get autoremove -y
                sudo apt-get update
                ;;
            amzn|fedora|centos|rhel)
                info "Uninstalling Node.js from $LINUX_PRETTY_NAME..."
                if command -v dnf >/dev/null 2>&1; then
                    sudo dnf remove -y nodejs
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum remove -y nodejs
                else
                    error "Neither dnf nor yum found. Cannot determine how to uninstall Node.js."
                    return 1
                fi
                # Remove repository configuration if NodeSource script created one.
                # This can be complex as the script might create /etc/yum.repos.d/nodesource-el*.repo
                # For simplicity, we'll just remove the package. Manual cleanup of repo files might be needed.
                warn "NodeSource repository configuration (e.g., in /etc/yum.repos.d/ or /etc/dnf/...) might need manual removal."
                ;;
            *)
                warn "Unsupported Linux distribution for Node.js auto-uninstallation: $LINUX_PRETTY_NAME. Please uninstall Node.js manually."
                return 1
                ;;
        esac
    elif [ "$OS_NAME" = "Darwin" ]; then
        if ! check_command_exists "brew"; then
            warn "Homebrew (brew) not found. Cannot uninstall Node.js automatically on macOS."
            return 1
        fi
        info "Uninstalling Node.js via Homebrew..."
        brew uninstall node
        info "Node.js uninstallation attempted via Homebrew. You might also want to run 'brew cleanup'."
    else
        warn "Unsupported OS for Node.js auto-uninstallation: $OS_NAME. Please uninstall Node.js manually."
        return 1
    fi
    info "Node.js uninstallation attempted."
}

# Function to ensure a given path is in the shell's configuration file for PATH
ensure_path_in_shell_config() {
    local path_to_add="$1"
    local detected_shell="$2"
    local config_file_path=""
    local add_line_cmd=""
    # Using a more specific comment to make it easier to check/remove later if needed
    local path_comment_marker="# Added by Neovim setup script for: $path_to_add"

    # Expand ~ if present at the start of the path, carefully
    eval expanded_path_to_add=$path_to_add

    case "$detected_shell" in
        bash)
            config_file_path="$HOME/.bashrc"
            # Check if a line setting this path (or one that includes it) exists AND if the marker comment is there
            if ! (grep -qF "$path_comment_marker" "$config_file_path" 2>/dev/null && grep -qF "$expanded_path_to_add" "$config_file_path" 2>/dev/null); then
                if [[ ":$PATH:" != *":$expanded_path_to_add:"* ]]; then
                    add_line_cmd="export PATH=\\\"$expanded_path_to_add:\\\$PATH\\\""
                else
                    info "'$expanded_path_to_add' is already in the current session PATH. Not adding to '$config_file_path' unless missing marker."
                    # Still add if marker is missing, to make script idempotent for its own additions
                    if ! grep -qF "$path_comment_marker" "$config_file_path" 2>/dev/null; then add_line_cmd="export PATH=\\\"$expanded_path_to_add:\\\$PATH\\\"" ; fi
                fi
            else
                info "'$expanded_path_to_add' seems to be already configured by this script in '$config_file_path'."
            fi
            ;;
        zsh)
            config_file_path="$HOME/.zshrc"
            if ! (grep -qF "$path_comment_marker" "$config_file_path" 2>/dev/null && grep -qF "$expanded_path_to_add" "$config_file_path" 2>/dev/null); then
                 if [[ ":$PATH:" != *":$expanded_path_to_add:"* ]]; then
                    add_line_cmd="export PATH=\\\"$expanded_path_to_add:\\\$PATH\\\""
                else
                    info "'$expanded_path_to_add' is already in the current session PATH. Not adding to '$config_file_path' unless missing marker."
                    if ! grep -qF "$path_comment_marker" "$config_file_path" 2>/dev/null; then add_line_cmd="export PATH=\\\"$expanded_path_to_add:\\\$PATH\\\"" ; fi
                fi
            else
                info "'$expanded_path_to_add' seems to be already configured by this script in '$config_file_path'."
            fi
            ;;
        fish)
            config_file_path="$HOME/.config/fish/config.fish"
            # fish_add_path is idempotent for fish_user_paths. We check for our comment and the specific command.
            if ! (grep -qF "$path_comment_marker" "$config_file_path" 2>/dev/null && grep -qF "fish_add_path \"$expanded_path_to_add\"" "$config_file_path" 2>/dev/null); then
                add_line_cmd="fish_add_path \"$expanded_path_to_add\""
            else
                info "'$expanded_path_to_add' seems to be already configured by this script in '$config_file_path'."
            fi
            ;;
        *)
            warn "Unsupported shell '$detected_shell' for automatic PATH configuration. Please add '$expanded_path_to_add' to your PATH manually."
            return
            ;;
    esac

    if [ -n "$add_line_cmd" ]; then
        if [ ! -f "$config_file_path" ] && [ "$detected_shell" = "fish" ]; then
            info "Fish config file '$config_file_path' does not exist. Creating it and its directory."
            mkdir -p "$(dirname "$config_file_path")"
            touch "$config_file_path"
        elif [ ! -f "$config_file_path" ]; then
            warn "Shell config file '$config_file_path' does not exist. Cannot add PATH automatically for $expanded_path_to_add. Please create the file or add manually."
            return
        fi

        info "Attempting to add '$expanded_path_to_add' to PATH in '$config_file_path'."
        echo "" >> "$config_file_path" # Add a newline for separation
        echo "$path_comment_marker" >> "$config_file_path"
        echo "$add_line_cmd" >> "$config_file_path"
        info "Successfully appended configuration for '$expanded_path_to_add' to '$config_file_path'."
        SHELL_CONFIG_MODIFIED=true
    fi
}

# --- Main Logic ---
MODE="install"
if [[ "$1" == "--remove" || "$1" == "uninstall" ]]; then
    MODE="uninstall"
fi

# --- Shell Detection (for PATH modification) ---
USER_SHELL_NAME=""
if [ -n "$SHELL" ]; then
    USER_SHELL_NAME=$(basename "$SHELL")
else
    # Fallback if $SHELL is not set, try to get from ps for current process
    USER_SHELL_NAME=$(ps -p $$ -o comm= | tr -d '-' | awk '{print $1}') # Get first field, remove trailing args if any
fi
info "Detected OS: $OS_NAME, Linux ID: ${LINUX_ID:-N/A}, Pretty Name: ${LINUX_PRETTY_NAME:-N/A}, User Shell: ${USER_SHELL_NAME:-unknown}"
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

    # Install all tools
    info "Starting installation of development tools..."
    [ "$proceed_rust" = true ] && install_rust_tools
    [ "$proceed_rust" = true ] && install_stylua # Needs cargo from Rust toolchain
    [ "$proceed_go" = true ] && install_go_tools
    [ "$proceed_python" = true ] && install_python_tools
    install_nodejs # Install Node.js for all relevant OSes

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

    # --- Configure PATH in shell config ---
    if [ -n "$USER_SHELL_NAME" ] && [ "$USER_SHELL_NAME" != "unknown" ]; then
        info "Attempting to configure PATH in your shell configuration file ($USER_SHELL_NAME)..."
        ensure_path_in_shell_config "~/.local/bin" "$USER_SHELL_NAME"
        ensure_path_in_shell_config "$(get_go_bin_dir)" "$USER_SHELL_NAME"
        # Only add cargo if rust was supposed to be processed.
        [ "$proceed_rust" = true ] && ensure_path_in_shell_config "~/.cargo/bin" "$USER_SHELL_NAME"
    else
        warn "Could not reliably determine user shell. Skipping automatic PATH configuration."
        warn "Please ensure ~/.local/bin, Go binary path, and ~/.cargo/bin are in your PATH."
    fi

    info "INSTALLATION process attempted."

elif [ "$MODE" = "uninstall" ]; then
    info "Starting linter and formatter UNINSTALLATION script..."

    if $proceed_rust; then uninstall_rust_tools; else warn "Skipping Rust tools uninstall (rustup not found)."; fi
    if $proceed_rust; then uninstall_stylua; else warn "Skipping stylua uninstall (cargo not found or stylua not installed via cargo)."; fi
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
    uninstall_nodejs # Uninstall Node.js
    info "UNINSTALLATION process attempted."
fi

info "---------------------------------------------------------------------"
info "Script finished."
info "Please review any error or warning messages above."

if [ "$MODE" = "install" ] && [ "$SHELL_CONFIG_MODIFIED" = true ]; then
    warn "IMPORTANT: Your shell configuration file was modified to update the PATH."
    warn "Please source your shell configuration file (e.g., 'source ~/.bashrc', 'source ~/.zshrc', 'source ~/.config/fish/config.fish') or open a new terminal session for these changes to take full effect."
fi

info "If installing, ensure all installed binaries are in your system's PATH."
info "You may need to restart your terminal session or Neovim for changes to take effect."
info "---------------------------------------------------------------------" 