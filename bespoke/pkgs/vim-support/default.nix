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
      pythonOverrides = self.buildPythonOverrides (pyself: pysuper: {
        # General language-specific support tools
        flake8-bugbear = pysuper.callPackage ./flake8-bugbear.nix { };
        flake8-per-file-ignores = pysuper.callPackage ./flake8-per-file-ignores.nix { };
      }) super.pythonOverrides;
    })
  ];
}
