{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      # General language-specific support tools
      fixjson = super.callPackage ./fixjson { };

      # Language Server Protocol servers
      clangd = super.callPackage ./langservers/clangd.nix { };
      vscode-css-langserver = super.callPackage ./langservers/vscode-css-languageserver-bin { };
      bash-language-server = super.callPackage ./langservers/bash-language-server { };
    })
  ];
}
