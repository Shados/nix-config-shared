{ config, lib, pkgs, ... }:
lib.mkMerge [
  { nixpkgs.overlays = lib.mkBefore [
      (self: super: {
        sn = (super.sn or { }) // {
          # We use this by specifying overrides in the below, they get fed down into all luaPackages
          luaOverrides = [];
          defineLuaPackageOverrides = super: overrides: {
            sn = super.sn // {
              luaOverrides = super.sn.luaOverrides ++ [ overrides ];
            };
          };
          overrideLuaPackages = luaPackages: overrides: let
            # The below is an arg-swapped wrapper
            buildLuaOverrides = currentOverrides: newOverrides: super.lib.composeExtensions newOverrides currentOverrides;
            baseOverride = (luaself: luaPackages);
            composedOverride = super.lib.foldl' (super.lib.flip super.lib.extends) (baseOverride) overrides;
          in super.lib.fix composedOverride;
        };
      })
    ];
  }
  { nixpkgs.overlays = [
      # Actually override the packages
      (self: super: let
        luaPackagesNames = [
          "lua51Packages"
          "lua52Packages"
          "lua53Packages"
          "luajitPackages"
        ];
        overriddenLuaPackage = name:
          { inherit name;
            value = super.sn.overrideLuaPackages super.${name} self.sn.luaOverrides;
          };
        overriddenLuaPackages = map overriddenLuaPackage luaPackagesNames;
      in builtins.listToAttrs overriddenLuaPackages)
    ];
  }
]
