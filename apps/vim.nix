{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    neovim-remote
    silver-searcher # `ag`
    universal-ctags
  ] ++ [
    # Language Servers
    clangd # c/c++
    hies # use hie-wrapper to launch correct HIE binary for project's GHC?
    # TODO need a solid solution for managing globally-available Python modules
    # before I can add optional deps properly?...
    python36Packages.python-language-server
    solargraph # Ruby
    rustup # includes the Rust Language Server
    go-langserver go
    vscode-css-langserver
  ] ++ [
    # Other per-language things (e.g. formatters, non-LSP linters)
    python36Packages.black # Strict style auto-formatting
    python36Packages.isort # Auto-sorts import statements
    python36Packages.cython # For Cython linting
    elmPackages.elm
    elmPackages.elm-format
    lua
    lua52Packages.luacheck
    vim-vint
  ];

  # cachix caches
  nix = {
    binaryCaches = [
      # Haskell IDE Engine
      "https://hie-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hie-nix.cachix.org-1:EjBSHzF6VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
    ];
  };
  nixpkgs.overlays = [
    (let
      rev = "96af698f0cfefdb4c3375fc199374856b88978dc";
      sha256 = "1ar0h12ysh9wnkgnvhz891lvis6x9s8w3shaakfdkamxvji868qa";
      # Get sha256 with e.g.: `nix-prefetch-url --unpack https://github.com/domenkozar/hie-nix/archive/96af698f0cfefdb4c3375fc199374856b88978dc.tar.gz`
    in self: super: {
      hies = (import (builtins.fetchTarball {
        url = "https://github.com/domenkozar/hie-nix/archive/${rev}.tar.gz";
        inherit sha256;
      }) {}).hies;
    })
  ];
}
