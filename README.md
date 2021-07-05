## Personal Neovim Configuration

My personal neovim configuration for daily coding.

Supported Language: C/C++, Rust, Python3

## Prerequisites

### Basic

* neovim 0.5+

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

* rust-analyzer

      git clone https://github.com/rust-analyzer/rust-analyzer.git && cd rust-analyzer
      cargo xtask install --server

* ccls

      git clone https://github.com/MaskRay/ccls.git && cd ccls
      sudo apt install clang cmake libclang-dev llvm-dev rapidjson-dev
      cmake -H. -BRelease
      cmake --build Release
      cd Release && sudo make install
    
  or

      sudo apt install ccls // debian

* python-language-server

      pip install 'python-language-server[all]'


## Installation

    cd ~/.config
    git clone https://github.com/mhxie/nvim.git
    nvim
    :PaqInstall
    :CheckHealth // troubleshoot any loading issues

## References

* https://github.com/neovim/neovim
* https://oroques.dev/notes/neovim-init/
* https://github.com/rockerBOO/awesome-neovim
* https://github.com/Shougo/deoplete.nvim
