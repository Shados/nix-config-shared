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
      tmux = pkgs.tmux.overrideAttrs  (oldAttrs: {
        # This git rev includes the 'exit-empty' option to control whether or
        # not the tmux server will quit when there are no running sessions
        name = "tmux-git";
        src = fetchFromGitHub {
          owner   = "tmux";
          repo    = "tmux";
          rev     = "9464b94f64eb5e8889e856458305256bacc3f94d";
          sha256  = "19kg0h8rlpz7pkg13y3zdd2j437ihhiggg7sf0w1kzh7zvvvl4fc";
        };
      });

      snap = callPackage ./snap.nix {};
      pastebin = callPackage ./pastebin.nix {};

      pywal = callPackage ./pywal.nix {};
      gvcci = callPackage ./gvcci.nix (
      let
        haselPython = pkgs.python3.override {
          packageOverrides = self: super: {
            hasel = super.callPackage ./hasel.nix {};
          };
        };
      in
      {
        # hasel = callPackage ./hasel.nix {};
        python3Packages = haselPython.pkgs;
      });

      # pythonPackages = python.pkgs;
    };
    perlPackageOverrides = pkgs: with pkgs; {
      LinuxFD = callPackage ./urxvt/extensions/LinuxFD.nix {
        inherit (perlPackages) buildPerlModule ModuleBuild TestException SubExporter;
      };
    };
  };
}
