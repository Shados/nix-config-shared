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
    })
  ];
}
