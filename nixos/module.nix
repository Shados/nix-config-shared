{ config, inputs, lib, pkgs, system, ... }:
let
  inherit (lib) mkBefore mkMerge mkOption mkOptionDefault singleton;
  pins = import ../pins;
in
{
  imports = [
    # Self-packaged and custom/bespoke packages & services
    ./bespoke
    # Standard userspace tooling & applications
    ./apps
    # Meta modules related to Nix/OS configuration itself
    ./meta
    # Security-focused configuration
    ./security
    # Service configuration
    ./services
    # System default configuration changes
    ./system

    # For working with stateless-root systems
    (pins.impermanence + /nixos.nix)
  ];


  options = {
    fragments.remote = mkOption {
      type = with lib.types; bool;
      default = true;
      description = ''
        Whether or not this system is remote (i.e. not one I will ever access
        with a physical keyboard and mouse).
      '';
    };
  };

  config = let
    nur-no-packages = import inputs.nur {
      nurpkgs = inputs.nixpkgs.legacyPackages.${system};
      pkgs = null;
    };
  in mkMerge [
    # Setup access to the Nix User Repository & my personal NUR Cachix cache
    { nix.settings = {
        substituters = singleton "https://shados-nur-packages.cachix.org";
        trusted-public-keys = singleton "shados-nur-packages.cachix.org-1:jGzLOsiYC+TlK8i7HZmNarRFf/LeZ0/J1BJ6NMpNAVU=";
      };
      nixpkgs.overlays = singleton inputs.nur.overlay;
    }
    # Pull in overlays from my NUR
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; mkBefore [
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
