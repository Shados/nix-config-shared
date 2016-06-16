{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {
    hostapd = callPackage ./hostapd-git {};
    hugo = callPackage ./hugo.nix {};
    rssh = callPackage ./rssh {};
    rxvt_unicode = callPackage ./urxvt24bit.nix {
      perlSupport = true;
      gdkPixbufSupport = true;
      unicode3Support = true;
    };
  };
}
