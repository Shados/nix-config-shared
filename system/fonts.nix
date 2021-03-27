{ config, lib, pkgs, ... }:

{
  fonts.fonts = lib.mkIf (!config.fragments.remote) (with pkgs; [
    corefonts # Microsoft free fonts
    cm_unicode
    stix-otf
    dejavu_fonts
    ipafont
    source-code-pro
  ]);
}
