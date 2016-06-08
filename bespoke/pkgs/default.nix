{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {
    hostapd = callPackage ./hostapd-git {};
    hugo = callPackage ./hugo.nix {};
    rssh = callPackage ./rssh {};
  };
}
