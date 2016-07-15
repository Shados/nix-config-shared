{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: rec {
    dmenu = pkgs.dmenu.override {
      patches = [
        ./dmenu-git-20151020-fuzzymatch.diff
      ];
    };
  };
}
