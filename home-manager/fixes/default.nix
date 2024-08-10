{ config, inputs, lib, pkgs, ... }:
with lib;
{
  nixpkgs.overlays = [
    (self: super: {
      geeqie = super.geeqie.overrideAttrs(oa: rec {
        configureFlags = oa.configureFlags or [] ++ [
          "--disable-gpu-accel" # GPU acceleration has been varyingly buggy and slow since ~1.6.0, disable it for now
        ];
      });
      obs-studio = if versionOlder (getVersion super.obs-studio) "30.2.0" then super.obs-studio.overrideAttrs(oa: rec {
        version = "30.2.0-rc1";
        src = super.fetchFromGitHub {
          owner = "obsproject"; repo = "obs-studio";
          rev = version;
          sha256 = "sha256-1y+4cIaRCLhPOvT5nBPt2duEP41JFOfden2q828AYT8=";
          fetchSubmodules = true;
        };
        patches = [
          (pkgs.path + "/pkgs/applications/video/obs-studio/Enable-file-access-and-universal-access-for-file-URL.patch")
          ./obs-nix.patch

          # Fix libobs.pc for plugins on non-x86 systems
          (super.fetchpatch {
            name = "fix-arm64-cmake.patch";
            url = "https://git.alpinelinux.org/aports/plain/community/obs-studio/broken-config.patch?id=a92887564dcc65e07b6be8a6224fda730259ae2b";
            hash = "sha256-yRSw4VWDwMwysDB3Hw/tsmTjEQUhipvrVRQcZkbtuoI=";
            includes = [ "*/CompilerConfig.cmake" ];
          })
        ];
        buildInputs = oa.buildInputs ++ (with super; [
          uthash cjson nv-codec-headers-12
        ]);
        cmakeFlags = oa.cmakeFlags ++ [
          "-DENABLE_AJA=0"
        ];
      }) else super.obs-studio;
      wrapOBS = super.callPackage (pkgs.path + "/pkgs/applications/video/obs-studio/wrapper.nix") { inherit (self) obs-studio; };
    })
    (self: super: super.lib.defineLuaPackageOverrides super [(luaself: luasuper: {
      luasystem = luasuper.luaLib.overrideLuarocks luasuper.luasystem (drv: {
        buildInputs = super.lib.optionals super.stdenv.isLinux [
          super.glibc.out
        ];
      });
    })])
    (self: super: with super.lib; {
      puddletag = super.puddletag.overridePythonAttrs(oa: {
        makeWrapperArgs = [
          "\${qtWrapperArgs[@]}"
        ];
      });
    })
  ];
  # Fix for home-manager issues #730 and #909 is using the non-"legacy" systemd
  # script, which for some reason isn't enabled by default
  systemd.user.startServices = true;
}
