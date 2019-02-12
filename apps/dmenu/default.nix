{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: rec {
    dmenu = pkgs.dmenu.overrideAttrs(oldAttrs: {
      patchFlags = "-p2";
      patches = [
        ./fuzzymatch.patch
      ];
    });
  };
}
