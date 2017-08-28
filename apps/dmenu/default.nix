{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: rec {
    dmenu = pkgs.dmenu.override {
      patches = [
        ./dmenu-fuzzymatch-20170603-f428f3e.diff
      ];
    };
  };
}
