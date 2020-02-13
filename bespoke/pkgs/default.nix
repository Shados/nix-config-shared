{ config, lib, pkgs, ... }:

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
          preferLocalBuild = true;
        } ''
          ${pkgs.unzip}/bin/unzip $src
          for f in */*_linux.x86_64.tar.gz; do
            cp $f $out
          done
        '';
      extractStandaloneFlash = ver: super.runCommand "flash_player_sa_linux_${ver}.x86_64.tar.gz" {
          src = flashSrcs."${ver}";
          preferLocalBuild = true;
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
        [ "31.0.0.122" "1rnxqw8kn96cqf821fl209bcmqva66j2p3wq9x4d43d8lqmsazhv" ]
        [ "32.0.0.171" "1zln5m82va44nzypkx5hdkq6kk3gh7g4sx3q603hw8rys0bq22bb" ]
        [ "32.0.0.293" "08igfnmqlsajgi7njfj52q34d8sdn8k88cij7wvgdq53mxyxlian" ]
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
    (self: super: let
      stdenv = super.overrideCC super.stdenv (gccWithPlugins);
      gccWithPlugins = with super; lowPrio (wrapCC (gcc.cc.override { enablePlugin = true; }));
    in rec {
      gcc-lua = super.callPackage ./gcc-lua.nix {
        lua = super.luajit;
        inherit stdenv;
      };
      gcc-lua-cdecl = super.callPackage ./gcc-lua-cdecl.nix {
        inherit stdenv;
        inherit (super.luajit.pkgs) buildLuaPackage;
      };
    })
    # Lua package overrides
    (import ./lua-packages/overlay.nix)
    # (self: super: super.sn.defineLuaPackageOverrides super (luaself: luasuper: {
    #   # alt-getopt = super.callPackage ./alt-getopt.nix { inherit (super.luaPackages) buildLuaPackage; };
    #   argparse = super.callPackage ./luaPackages/argparse.nix {
    #     inherit (luasuper) lua buildLuaPackage;
    #   };

    #   moonscript = super.callPackage ./luaPackages/moonscript.nix rec {
    #     inherit (luasuper) lua buildLuarocksPackage lpeg luafilesystem;
    #     inherit (luaself) argparse busted loadkit;
    #   };

    #   moonpick = super.callPackage ./luaPackages/moonpick.nix {
    #     inherit (luasuper) buildLuaPackage;
    #     inherit (luaself) moonscript;
    #   };
    # }))
    (self: super: with super.lib; {
      cataclysm-dda-git = (super.cataclysm-dda-git.overrideAttrs(oldAttrs: rec {
        version = "2019-03-05"; # jenkinks build #8566 https://ci.narc.ro/job/Cataclysm-Multijob/8566/
        name = "cataclysm-dda-git-${version}";
        src = super.fetchgit {
          url = "https://github.com/CleverRaven/Cataclysm-DDA.git";
          rev = "d5cafd3e5a785f43164e3ff3e1cb60dd7fefde94";
          sha256 = "0srpc56p092ml65jg33mv1nqksk2c55d9nqyhgmchkff4zxbrba3";
          leaveDotGit = true;
        };
        makeFlags = oldAttrs.makeFlags ++ [
          "VERSION=git-${version}-${substring 0 8 src.rev}"
        ];
        patches = []; # Disable unnecessary patch (might be needed on Darwin?)
        enableParallelBuilding = true; # Apparently Hydra has issues with building this in parallel

        # Fix Lua support
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with super; [
          makeWrapper git
        ]);
        postInstall = ''
          for bin in $out/bin/*; do
            wrapProgram "$bin" \
              --prefix LUA_PATH  ';' "$out/share/cataclysm-dda/lua/?.lua;$LUA_PATH;"   \
              --prefix LUA_CPATH ';' "$LUA_CPATH;"
          done
        '';
      })).override (with super; {
        # Use luajit and clang!
        stdenv = clangStdenv;
        callPackage = newScope (super // {
          lua = lua;
        });
      });
    })
    (self: super: with super.lib; let inherit (super) callPackage; in {
      rxvt_unicode = callPackage ./urxvt {
        perlSupport = true;
        gdkPixbufSupport = true;
        unicode3Support = true;
      };
      urxvt-config-reload = callPackage ./urxvt/extensions/urxvt-config-reload {
        inherit (super.perlPackages) AnyEvent LinuxFD CommonSense SubExporter
        DataOptList ParamsUtil SubInstall;
      };
      rxvt_unicode-with-plugins = callPackage ./urxvt/wrapper.nix {
        inherit (super.perlPackages) makePerlPath;
        plugins = [
          self.urxvt-config-reload
          super.urxvt_autocomplete_all_the_things
          super.urxvt_perl
          super.urxvt_perls
          super.urxvt_tabbedex
          super.urxvt_font_size
          super.urxvt_theme_switch
          super.urxvt_vtwheel
        ];
      };
      urxvtconfig = callPackage ./urxvtconfig.nix {
        inherit (super.qt5) qtbase qmake;
        inherit (super.xorg) libXft;
      };

      snap = callPackage ./snap.nix {};
      pastebin = callPackage ./pastebin.nix {};

      pywal = callPackage ./pywal.nix {};
      gvcci = callPackage ./gvcci.nix (
      let
        haselPython = super.python3.override {
          packageOverrides = self: super: {
            hasel = super.callPackage ./hasel.nix {};
          };
        };
      in
      {
        # hasel = callPackage ./hasel.nix {};
        python3Packages = haselPython.pkgs;
      });

      dmenu = super.dmenu.overrideAttrs(oldAttrs: {
        patchFlags = "-p2";
        patches = [
          ./dmenu/fuzzymatch.patch
        ];
      });

      # Add the `dunstify` notifier binary to $out
      dunst = super.dunst.override { dunstify = true; };

      all-hies = import (fetchTarball "https://github.com/infinisil/all-hies/tarball/master") {};

      waterfox = let
        waterfox-unwrapped = waterfox-unwrapped-base.overrideAttrs(oa: let
          binaryName = "waterfox";
          browserName = binaryName;
          execdir = "/bin";
        in {
          preConfigure = oa.preConfigure + ''
            # TODO make BINDGEN_CFLAGS dependent on ffversion >= 63, wtf
            rm $MOZCONFIG
            unset MOZCONFIG
          '';
          postInstall = ''
            # Remove SDK cruft. FIXME: move to a separate output?
            rm -rf $out/share/idl $out/include $out/lib/${binaryName}-devel-*
            libDir=$out/lib/${binaryName}

            # Needed to find Mozilla runtime
            gappsWrapperArgs+=(--argv0 "$out/bin/.${binaryName}-wrapped")
          '';
          postFixup = ''
            # Fix notifications. LibXUL uses dlopen for this, unfortunately; see #18712.
            patchelf --set-rpath "${lib.getLib super.libnotify
              }/lib:$(patchelf --print-rpath "$out"/lib/${binaryName}*/libxul.so)" \
                "$out"/lib/${binaryName}*/libxul.so
          '';
          installCheckPhase = ''
            # Some basic testing
            "$out${execdir}/${browserName}" --version
          '';
        });
        waterfox-unwrapped-base = firefox-common {
          pname = "waterfox";
          ffversion = "56.2.12";
          extraNativeBuildInputs = [
            (super.ensureNewerSourcesHook { year = "1980"; })
          ];
          src = super.fetchFromGitHub {
            owner  = "MrAlex94";
            repo   = "Waterfox";
            rev    = "56.2.12";
            sha256 = "0fjg7c8vp3vlhwv0kpnhlslbibsxsapl7d6v6s0dxcyjkkz5i01v";
          };
          patches = [
            "${pkgs.path}/pkgs/applications/networking/browsers/firefox/fix-pa-context-connect-retval.patch"
            ./waterfox/wf-buildconfig.patch
          ];
          extraConfigureFlags = [
            "--enable-stylo=build"
            "--enable-content-sandbox"
            "--with-app-name=waterfox"
            "--with-app-basename=Waterfox"
            "--with-branding=browser/branding/unofficial"
            "--with-distribution-id=org.waterfoxproject"
          ];
          meta = {
            description = "A web browser designed for privacy and user choice";
            longDescription = ''
              The Waterfox browser is a specialised modification of the Mozilla
              platform, designed for privacy and user choice in mind.

              Other modifications and patches that are more upstream have been
              implemented as well to fix any compatibility/security issues that Mozilla
              may lag behind in implementing (usually due to not being high priority).
              High request features removed by Mozilla but wanted by users are retained
              (if they aren't removed due to security).
            '';
            homepage    = https://www.waterfoxproject.org;
            maintainers = with maintainers; [ arobyn ];
            platforms   =  [ "x86_64-linux" ];
            license     = licenses.mpl20;
          };
        };
        firefox-common = with super; opts: super.callPackage
          (import "${pkgs.path}/pkgs/applications/networking/browsers/firefox/common.nix" opts)
          { inherit (gnome2) libIDL;
            libpng = libpng_apng;
            gnused = gnused_422;
            icu = icu63;
            inherit (darwin.apple_sdk.frameworks) CoreMedia ExceptionHandling
                                                  Kerberos AVFoundation MediaToolbox
                                                  CoreLocation Foundation AddressBook;
            inherit (darwin) libobjc;

            enableOfficialBranding = false;
            privacySupport = true;
            gssSupport = false;
            geolocationSupport = false;
          };
      in super.wrapFirefox waterfox-unwrapped {
        browserName = "waterfox";
      };
      waterfox-alpha = super.wrapFirefox self.waterfox-alpha-unwrapped {
        browserName = "waterfox";
        nameSuffix = "-alpha";
      };
      waterfox-alpha-unwrapped = let
        gitVersion = "2019.10-current-1";
        waterfox-unwrapped-base = (firefox-common {
          pname = "waterfox";
          ffversion = "68.0-${gitVersion}";
          src = super.fetchFromGitHub {
            owner  = "MrAlex94";
            repo   = "Waterfox";
            rev    = "d8326e125b8fde7e73d44891df935504b12362b3";
            sha256 = "02x2kmywfa6qv9c226qhrxbmsq0ns66s8z9b4lngls2nr06f8da1";
          };
          patches = [
            "${pkgs.path}/pkgs/applications/networking/browsers/firefox/no-buildconfig-ffx65.patch"
          ];
          extraConfigureFlags = [
            "--enable-content-sandbox"
            "--with-app-name=waterfox"
            "--with-app-basename=Waterfox"
            "--with-branding=browser/branding/waterfox"
            "--with-distribution-id=net.waterfox"
          ];
          meta = {
            description = "A web browser designed for privacy and user choice";
            longDescription = ''
              The Waterfox browser is a specialised modification of the Mozilla
              platform, designed for privacy and user choice in mind.

              Other modifications and patches that are more upstream have been
              implemented as well to fix any compatibility/security issues that Mozilla
              may lag behind in implementing (usually due to not being high priority).
              High request features removed by Mozilla but wanted by users are retained
              (if they aren't removed due to security).
            '';
            homepage    = https://www.waterfoxproject.org;
            maintainers = with maintainers; [ arobyn ];
            platforms   =  [ "x86_64-linux" ];
            license     = licenses.mpl20;
          };
        }).overrideAttrs(oa: {
          patches = [
            "${pkgs.path}/pkgs/applications/networking/browsers/firefox/no-buildconfig-ffx65.patch"
          ];
          hardeningDisable = [ "format" ]; # -Werror=format-security
        });
        firefox-common = with super; opts: super.callPackage
          (import "${pkgs.path}/pkgs/applications/networking/browsers/firefox/common.nix" opts)
          { inherit (gnome2) libIDL;
            libpng = libpng_apng;
            gnused = gnused_422;
            icu = icu63;
            inherit (darwin.apple_sdk.frameworks) CoreMedia ExceptionHandling
                                                  Kerberos AVFoundation MediaToolbox
                                                  CoreLocation Foundation AddressBook;
            inherit (darwin) libobjc;
            inherit (rustPackages_1_38_0) cargo rustc;

            enableOfficialBranding = false;
            privacySupport = true;
          };
      in waterfox-unwrapped-base.overrideAttrs(oa: let
        binaryName = "waterfox";
        browserName = binaryName;
        execdir = "/bin";
      in {
        preConfigure = oa.preConfigure + ''
          echo "MOZ_REQUIRE_SIGNING=0" >> $MOZCONFIG
          echo "MOZ_ADDON_SIGNING=0" >> $MOZCONFIG
          echo "ac_add_options \"MOZ_ALLOW_LEGACY_EXTENSIONS=1\"" >> $MOZCONFIG
        '';
        postInstall = ''
          # Remove SDK cruft. FIXME: move to a separate output?
          rm -rf $out/share/idl $out/include $out/lib/${binaryName}-devel-*
          libDir=$out/lib/${binaryName}

          # Needed to find Mozilla runtime
          gappsWrapperArgs+=(--argv0 "$out/bin/.${binaryName}-wrapped")
        '';
        postFixup = ''
          # Fix notifications. LibXUL uses dlopen for this, unfortunately; see #18712.
          patchelf --set-rpath "${lib.getLib super.libnotify
            }/lib:$(patchelf --print-rpath "$out"/lib/${binaryName}*/libxul.so)" \
              "$out"/lib/${binaryName}*/libxul.so
        '';
        installCheckPhase = ''
          # Some basic testing
          "$out${execdir}/${browserName}" --version
        '';
      });
    })
    # Equivalents to nixos-help for nix and nixpkgs manuals
    (self: super: let
      writeHtmlHelper = name: htmlPath: super.writeScriptBin name /*ft=sh*/''
        #!${super.bash}/bin/bash
        browser="$(
          IFS=: ; for b in $BROWSER; do
            [ -n "$(type -P "$b" || true)" ] && echo "$b" && break
          done
        )"
        if [ -z "$browser" ]; then
          browser="$(type -P xdg-open || true)"
          if [ -z "$browser" ]; then
            browser="$(type -P w3m || true)"
            if [ -z "$browser" ]; then
              echo "$0: unable to start a web browser; please set \$BROWSER"
              exit 1
            fi
          fi
        fi
        $browser ${htmlPath}
      '';
    in {
      nix-help = let
        # TODO: Look into building the manual from source instead of using the
        # prebuilt version distributed in the source-distribution-tarball that
        # the Nix derivation is built from?
        nixSrc = super.nix.src;
        manual = super.runCommand "nix-manual-source" {
        } ''
          mkdir -p $out/share/doc/nix
          tar xvf ${nixSrc}
          mv nix-*/doc/manual/* $out/share/doc/nix/
        '';
      in writeHtmlHelper "nix-help" "${manual}/share/doc/nix/manual.html";
      nixpkgs-help = let
        # NOTE: There are some interesting variables to extend or overwrite to
        # affect the produced style:
        # - HIGHLIGHTJS (env, string)
        # - xlstFlags (list)
        # - XMLFORMT_CONFIg (maybe?)
        manual = super.callPackage "${super.path}/doc" { };
      in writeHtmlHelper "nixpkgs-help" "${manual}/share/doc/nixpkgs/manual.html";
      nixos-options-help = let
        manual = config.system.build.manual.manualHTML;
      in writeHtmlHelper "nixos-options-help" "${manual}/share/doc/nixos/options.html";
    })
  ];

  nixpkgs.config = {
    perlPackageOverrides = pkgs: with pkgs; {
      LinuxFD = callPackage ./urxvt/extensions/LinuxFD.nix {
        inherit (perlPackages) buildPerlModule ModuleBuild TestException SubExporter;
      };
    };
  };
}
