{ config, lib, pkgs, ... }:

{
  imports = [
    ./kernels
  ];
  nixpkgs.overlays = [
    (self: super: with super.lib; let inherit (super) callPackage; in {
      snap = callPackage ./snap.nix {};
      pastebin = callPackage ./pastebin.nix {};

      all-hies = import (fetchTarball "https://github.com/infinisil/all-hies/tarball/master") {};

      # Python overrides
      pythonOverrides = self.sn.buildPythonOverrides (pyself: pysuper: {
        # General language-specific support tools
        flake8-bugbear = pysuper.callPackage ./flake8-bugbear.nix { };
        flake8-per-file-ignores = pysuper.callPackage ./flake8-per-file-ignores.nix { };
      }) super.pythonOverrides;
    })
  ];
}
