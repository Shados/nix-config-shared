{ config, lib, pkgs, ... }:
{
  imports = [
    # Temporary fixes that have yet to hit nixos-unstable channel
    ./fixes
  ];

  config = let
    nur-no-packages = import (import ../pins).nur { };
  in lib.mkMerge [
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; lib.mkBefore [
        lua-overrides
      ];
    }
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; [
        lua-packages
        fixes
        oldflash
        dochelpers
      ];
    }
  ];
}
