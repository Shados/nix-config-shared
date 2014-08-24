{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {
    hah = callPackage ./hah {};
    hostapd = callPackage ./hostapd-git {};
    hugo = callPackage ./hugo.nix {};
  };
}
