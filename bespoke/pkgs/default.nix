{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; rec {
    hugo = callPackage ./hugo.nix {};
    rxvt_unicode = callPackage ./urxvt24bit.nix {
      perlSupport = true;
      gdkPixbufSupport = true;
      unicode3Support = true;
    };
  };
}
