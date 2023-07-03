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
}
