{ config, lib, pkgs, ... }:
with lib;
{
  nix = {
    # 0 will auto-detect the number of physical cores and use that
    buildCores = mkDefault 0;
    useSandbox = true;
    gc = {
      automatic = true;
      dates = "*-*-1 05:15"; # 5:15 AM on the first of each month
      options = "--delete-older-than 90d"; # Delete all generations older than 90 days
    };
    autoOptimiseStore = true;

    # Have the builders run at low CPU and IO priority
    daemonIONiceLevel = mkDefault 7;
    daemonNiceLevel = mkDefault 19;
    trustedUsers = [
      "root"
      "shados"
    ];

    binaryCaches = mkOrder 999 [
      "https://cache.nixos.org/"
    ];
  };
  # Add an opt-in flake-enabled Nix command under the name 'flk'
  environment.systemPackages = [
    (pkgs.writeScriptBin "flk" ''
      #!/usr/bin/env bash
      exec ${pkgs.nixFlakes}/bin/nix --experimental-features "nix-command flakes" "$@"
    '')
  ];
}
