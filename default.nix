# Baseline SN NixOS configuration
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments;
in

{
  imports = [
    # Custom/bespoke packages & services
    ./bespoke
    # Standard userspace tooling & applications
    ./apps
    # Temporary fixes that have yet to hit nixos-unstable channel
    ./fixes
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
    })
    {
      boot.cleanTmpDir = true;

      # Internationalisation & localization properties.
      i18n = {
        consoleFont   = pkgs.lib.mkDefault "lat9w-16";
        defaultLocale = "en_US.UTF-8";
      };
      time.timeZone = "Australia/Melbourne";

      # Config for various standard services & programs

      programs = {
        atop.settings = {
          interval = 1;
        };
        bash = {
          enableCompletion = true;
          #shellAliases = {};
        };
      };
    }
  ];
}
