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

      # Python overrides
      python36 = super.python36.override {
        # Careful, we're using a different self and super here!
        packageOverrides = self: super: {
          # General language-specific support tools
          flake8-bugbear = super.callPackage ./flake8-bugbear.nix { };
        };
      };
      python36Packages = super.recurseIntoAttrs self.python36.pkgs;
    })
  ];
}
