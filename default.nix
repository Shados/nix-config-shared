# Baseline SN NixOS configuration
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.fragments;
in

{
  imports = [
    # Self-packaged and custom/bespoke packages & services
    ./bespoke
    # Standard userspace tooling & applications
    ./apps
    # nixpkgs overlays as generic (non-NixOS) modules
    ./overlays
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

  config = mkMerge [
    (mkIf cfg.remote {
      i18n.consoleKeyMap = ./system/sn.map.gz;
      systemd.enableEmergencyMode = mkDefault false;
    })
    {
      boot.cleanTmpDir = true;

      # Internationalisation & localization properties.
      i18n = {
        consoleFont   = mkDefault "lat9w-16";
        defaultLocale = "en_US.UTF-8";
      };
      time.timeZone = "Australia/Melbourne";

    }
  ];
}
