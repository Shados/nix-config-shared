{ config, pkgs, ... }:

{
  nixpkgs.config = {
    packageOverrides = pkgs: with pkgs; rec {
      rxvt_unicode = callPackage ./urxvt {
        perlSupport = true;
        gdkPixbufSupport = true;
        unicode3Support = true;
      };
      urxvt-config-reload = callPackage ./urxvt/extensions/urxvt-config-reload {
        inherit (perlPackages) AnyEvent LinuxFD CommonSense
        SubExporter DataOptList ParamsUtil SubInstall;
      };
      rxvt_unicode-with-plugins = callPackage ./urxvt/wrapper.nix {
        plugins = [
          urxvt-config-reload
          urxvt_autocomplete_all_the_things
          urxvt_perl
          urxvt_perls
          urxvt_tabbedex
          urxvt_font_size
          urxvt_theme_switch
          urxvt_vtwheel
        ];
      };
    };
    perlPackageOverrides = pkgs: with pkgs; {
      LinuxFD = callPackage ./urxvt/extensions/LinuxFD.nix {
        inherit (perlPackages) buildPerlModule ModuleBuild TestException SubExporter;
      };
    };
  };
}
