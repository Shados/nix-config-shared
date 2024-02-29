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
      youtube-dl = super.youtube-dl.overrideAttrs(oa: {
        patches = oa.patches or [] ++ [
          ../fixes/youtube-dl-uploader-id.patch
        ];
      });
    })
  ];
  # Fix for home-manager issues #730 and #909 is using the non-"legacy" systemd
  # script, which for some reason isn't enabled by default
  systemd.user.startServices = true;
}
