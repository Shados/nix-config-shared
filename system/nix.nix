{ config, lib, pkgs, ... }:
{
  nix = {
    useSandbox = true;
    gc = {
      automatic = true;
      dates = "*-*-1 05:15"; # 5:15 AM on the first of each month
      options = "--delete-older-than 90d"; # Delete all generations older than 90 days
    };
    extraOptions = ''
      auto-optimise-store = true
    '';

    # Have the builders run at low CPU and IO priority
    daemonIONiceLevel = 7;
    daemonNiceLevel = 19;
    trustedUsers = [
      "root"
      "shados"
    ];

    binaryCaches = lib.mkOrder 999 [
      "https://cache.nixos.org/"
    ];
  };
}
