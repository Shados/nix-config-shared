# Baseline SN NixOS configuration
{ config, lib, pkgs, ... }:
# TODO Prettify console? Fonts, colour scheme?
with lib;
{
  imports = [
    # Self-packaged and custom/bespoke packages & services
    ./bespoke
    # Standard userspace tooling & applications
    ./apps
    # Meta modules related to Nix/OS configuration itself
    ./meta
    # Conveniently packaged system 'functional profiles', including
    # container/VM profiles
    ./profiles
    # Security-focused configuration
    ./security
    # Service configuration
    ./services
    # System default configuration changes
    ./system
  ];


  options = {
    fragments.remote = mkOption {
      type = with types; bool;
      default = true;
      description = ''
        Whether or not this system is remote (i.e. not one I will ever access
        with a physical keyboard and mouse).
      '';
    };
  };

  config = let
    nur-no-packages = import (import ./pins).nur { };
    nur = import (import ./pins).nur { inherit pkgs; };
  in mkMerge [
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
        python-overrides
      ];
    }
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; [
        lua-packages
        python-packages
        fixes
        oldflash
        dochelpers
      ];
    }
  ];
}
