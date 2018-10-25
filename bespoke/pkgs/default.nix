{ config, pkgs, ... }:

{
  imports = [
    ./kernels
    ./vim-support
  ];
  nixpkgs.overlays = [
    # Pinned old flashplayer versions
    (self: super: let
      # Helpers {{{
      extractNPAPIFlash = ver: super.runCommand "flash_player_npapi_linux_${ver}.x86_64.tar.gz" {
          src = flashSrcs."${ver}";
        } ''
          ${pkgs.unzip}/bin/unzip $src
          for f in */*_linux.x86_64.tar.gz; do
            cp $f $out
          done
        '';
      extractStandaloneFlash = ver: super.runCommand "flash_player_sa_linux_${ver}.x86_64.tar.gz" {
          src = flashSrcs."${ver}";
        } ''
          ${pkgs.unzip}/bin/unzip $src
          for f in */*_linux_sa.x86_64.tar.gz; do
            cp $f $out
          done
        '';
      mkFlashUrl = ver: "https://fpdownload.macromedia.com/pub/flashplayer/installers/archive/fp_${ver}_archive.zip";
      mkFlashSrc = ver: sha256: super.fetchurl {
        url = mkFlashUrl ver;
        inherit sha256;
      };
      mkFlashSrcs = verHashList: let
          version_attrs = map (vh: rec {
            name = builtins.elemAt vh 0;
            value = mkFlashSrc name (builtins.elemAt vh 1);
          }) verHashList;
        in builtins.listToAttrs version_attrs;
      # }}}
      flashSrcs = mkFlashSrcs [
        [ "30.0.0.113" "117hw34bxf5rncfqn6bwvb66k2jv99avv1mxnc2pgvrh63bp3isp" ]
        [ "30.0.0.134" "1cffzzkg6h8bns3npkk4a87qqfnz0nlr7k1zjfc2s2wzbi7a94cc" ]
        [ "30.0.0.154" "14p0lcj8x09ivk1h786mj0plzz2lkvxkbw3w15fym7pd0nancz88" ]
        [ "31.0.0.108" "06kvwlzw2bjkcxzd1qvrdvlp0idvm54d1rhzn5vq1vqdhs0lnv76" ]
        # [ "31.0.0.122" "" ]
      ];
    in {
      flashplayer = let
          curFlashVer = super.lib.getVersion super.flashplayer;
        in if builtins.hasAttr curFlashVer flashSrcs
          then super.flashplayer.overrideAttrs (oldAttrs: rec {
            src = extractNPAPIFlash curFlashVer;
          })
          else super.flashplayer;
      flashplayer-standalone = let
          curFlashVer = super.lib.getVersion super.flashplayer-standalone;
        in if builtins.hasAttr curFlashVer flashSrcs
          then super.flashplayer-standalone.overrideAttrs (oldAttrs: rec {
            src = extractStandaloneFlash curFlashVer;
          })
          else super.flashplayer-standalone;
      # Helper so you can do e.g. `nix-prefetch-flash 30.0.0.134` to prefetch
      # and get the sha256 hash
      nix-prefetch-flash = super.writeScriptBin "nix-prefetch-flash" ''
          #!${super.dash}/bin/dash
          url="${mkFlashUrl "$1"}"
          nix-prefetch-url "$url"
        '';
    })
    # Fix flashplayer-standalone hw gpu stuff
    (self: super: {
      flashplayer-standalone = super.flashplayer-standalone.overrideAttrs(oldAttrs: let
        libs = super.stdenv.lib.makeLibraryPath [ super.libGL ];
      in {
        nativeBuildInputs = with super; oldAttrs.nativeBuildInputs ++ [ makeWrapper libGL ];
        rpath = oldAttrs.rpath + ":" + libs;
        # postInstall = ''
        #   for prog in "$out/bin/"*; do
        #     wrapProgram "$prog" --prefix LD_LIBRARY_PATH ":" ${libs}
        #   done
        # '';
      });
    })
  ];

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

      waterfox = let
        waterfox-unwrapped = callPackage ./waterfox {
          # # https://forum.palemoon.org/viewtopic.php?f=57&t=15296#p111146
          # stdenv = overrideCC stdenv gcc5;
          # stdenv = overrideCC clangStdenv gcc5;
          stdenv = llvmPackages_6.libcxxStdenv;
          llvmPackages = llvmPackages_6;
          inherit (gnome2) libIDL;
          libpng = libpng_apng;
          python = python2;
          gnused = gnused_422;
          icu = icu59;
          hunspell = pkgs.hunspell.override {
            stdenv = llvmPackages_6.libcxxStdenv;
          };
        };
      in wrapFirefox waterfox-unwrapped {
        browserName = "waterfox";
      };

      # pythonPackages = python.pkgs;
    };
    perlPackageOverrides = pkgs: with pkgs; {
      LinuxFD = callPackage ./urxvt/extensions/LinuxFD.nix {
        inherit (perlPackages) buildPerlModule ModuleBuild TestException SubExporter;
      };
    };
  };
}
