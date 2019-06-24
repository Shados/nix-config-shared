{ config, lib, ... }:
lib.mkMerge [
  # Lua cross-version overlay support
  { nixpkgs.overlays = lib.mkBefore [
      (self: super: with super.lib; let
        luaNames = [
          (nameAndPkgs "lua5_1" "lua51Packages" )
          (nameAndPkgs "lua5_2" "lua52Packages" )
          (nameAndPkgs "lua5_3" "lua53Packages" )
          (nameAndPkgs "luajit" "luajitPackages" )
        ];
        nameAndPkgs = name: pkgs: { interpreter = name; packages = pkgs; };
        overrideLuaPackages = luaPackages: overrides: let
          baseOverride = (luaself: luasuper: {});
          composedOverride = foldl' (composeExtensions) (baseOverride) overrides;
        in composedOverride;
        overriddenLua = {interpreter, packages}: let
          packageOverrides = overrideLuaPackages super.${interpreter}.pkgs self.sn.luaOverrides;
          newLua = super.${interpreter}.override { inherit packageOverrides; };
        in [
          { name = interpreter; value = newLua; }
          { name = packages; value = newLua.pkgs; }
        ];
        overriddenLuas = concatMap overriddenLua luaNames;
      in {
        sn = (super.sn or { }) // {
          # We use this by specifying overrides in the below, they get fed down into all luaPackages
          luaOverrides = [];
          defineLuaPackageOverrides = super: overrides: {
            sn = super.sn // {
              luaOverrides = super.sn.luaOverrides ++ [ overrides ];
            };
          };
        };
      } // builtins.listToAttrs overriddenLuas)
    ];
  }
]
