{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {
    datacoin-hp = callPackage ./datacoin-hp-git.nix { 
      libdb = callPackage ./libdb.nix {}; 
    };
    hah = callPackage ./hah {};
    hostapd = callPackage ./hostapd-git {};
  };
}
