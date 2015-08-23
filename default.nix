# Baseline SN NixOS configuration
{ config, pkgs, ... }:

{
  imports = [
    # Custom/bespoke packages & services
    ./bespoke

    # Standard userspace tooling & applications
    ./apps

    # Conveniently packaged system 'functional profiles', including container/VM profiles
    ./profiles

    # Security-focused configuration
    ./security
    # Service configuration
    ./services
    # System default configuration changes
    ./system
  ];

  boot.cleanTmpDir = true;

  # Internationalisation & localization properties.
  i18n = {
    consoleFont = "lat9w-16";
    defaultLocale = "en_US.UTF-8";
    consoleKeyMap = ./system/sn.map.gz;
  };
  time.timeZone = "Australia/Melbourne";

  # Config for various standard services & progresm
  services.cron.enable = false; # TODO: Make this the default in nix, convert all modules to use systemd timers

  nix = {
    useChroot = true;
    gc = {
      automatic = true;
      dates = "04:45";
      options = "--delete-older-than 30d"; # Delete all generations older than 90 days 
    };
    extraOptions = ''
      auto-optimise-store = true
    '';
  };

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
