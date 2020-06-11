{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    # Temporary fixes that have yet to hit nixos-unstable channel
    ./fixes
  ];

  config = let
    nur-no-packages = import (import ../pins).nur { };
    nur = import (import ../pins).nur { inherit pkgs; };
  in lib.mkMerge [
    # Setup access to the Nix User Repository & my personal NUR Cachix cache
    { nix = {
        binaryCaches = singleton "https://shados-nur-packages.cachix.org";
        binaryCachePublicKeys = singleton "shados-nur-packages.cachix.org-1:jGzLOsiYC+TlK8i7HZmNarRFf/LeZ0/J1BJ6NMpNAVU=";
      };
      nixpkgs.overlays = singleton (self: super: { inherit nur; });
    }
    # Pull in overlays from my NUR
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
