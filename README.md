## Personal Neovim Configuration

Supported Language: C/C++, Rust, Python3

## Prerequisites

### Basic

* neovim 0.8+

      git clone https://github.com/neovim/neovim.git && cd neovim
      make CMAKE_BUILD_TYPE=Release
      sudo make install

  or

      sudo apt-get install neovim // Debian

* paq-nvim

      git clone --depth=1 https://github.com/savq/paq-nvim.git \
      "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/paqs/start/paq-nvim

* deoplete.nvim

      pip3 install --user pynvim
      :UpdateRemotePlugin

### Language Servers & Linters

* rust-analyzer & rustfmt

      git clone https://github.com/rust-analyzer/rust-analyzer.git && cd rust-analyzer
      cargo xtask install --server

      # if failed or not work, update your rust to the latest release
      rustup toolchain install stable

      # install with pkg manager on termux
      pkg install rust-analyzer

* ccls & clang-format

      git clone https://github.com/MaskRay/ccls.git && cd ccls
      sudo apt install clang cmake libclang-dev llvm-dev rapidjson-dev
      cmake -H. -BRelease
      cmake --build Release
      cd Release && sudo make install

  or

      sudo apt install ccls // debian
      sudo apt-get install clang-format

      # install with pkg manager on termux
      pkg install ccls

* python-language-server & black

      pip install "python-lsp-server[all]"


## Installation

    cd ~/.config
    git clone https://github.com/mhxie/nvim.git
    nvim
    :PaqInstall
    :CheckHealth // troubleshoot any loading issues
    :PaqUpdate
    :TSUninstall all // uninstall all parsers when updated

## TODO

* more language support (YAML, TOML, HTML ...)
* add code analysis tools (e.g. facebook infer)

## References

* https://github.com/neovim/neovim
* https://oroques.dev/notes/neovim-init/
* https://github.com/rockerBOO/awesome-neovim
* https://github.com/Shougo/deoplete.nvim
