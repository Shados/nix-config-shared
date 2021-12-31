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
    daemonIOSchedClass = "idle";
    # FIXME breaks fpc builds because they unilaterally attempt to set cpu
    # priority/class and fail without a real warning if this is set
    # daemonCPUSchedPolicy = "idle";
    trustedUsers = [
      "root"
      "shados"
    ];

    binaryCaches = mkOrder 999 [
      "https://cache.nixos.org/"
    ];

    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
