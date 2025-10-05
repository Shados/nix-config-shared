{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkBefore
    mkDefault
    mkMerge
    mkOrder
    singleton
    ;
in
{
  config = mkMerge [
    {
      nix = {
        gc = {
          automatic = true;
          dates = "*-*-1 05:15"; # 5:15 AM on the first of each month
          options = "--delete-older-than 90d"; # Delete all generations older than 90 days
        };

        optimise = {
          dates = singleton "*-*-2 05:15"; # 5:15 Am on the second of each month
          automatic = !config.boot.isContainer;
        };

        extraOptions = ''
          experimental-features = nix-command flakes
        '';
        settings = {
          sandbox = true;
          trusted-users = [
            "shados"
          ];
          substituters = mkOrder 999 [
            "https://cache.nixos.org/"
          ];
          auto-optimise-store = true;
        };

        # TODO: Figure out HM equivalent for darwin only
        # Pin nixpkgs flake registry to the current-system nixpkgs flake input
        registry.nixpkgs = {
          exact = true;
          flake = inputs.nixpkgs;
        };

        # Pin nixpkgs channel to the flake
        nixPath = mkBefore (singleton "nixpkgs=flake:nixpkgs");
      };
    }
    # Limit memory, IO, and CPU impact of Nix builds and GC runs
    {
      # Ensure build jobs are a more likely target for the OOM killer than user
      # and system processes (100 is user slice default, 500 is
      # systemd-coredumpd)
      systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = mkDefault 250;

      # Have the builders run at low CPU and IO priority
      nix.daemonIOSchedClass = "idle";
      nix.daemonCPUSchedPolicy = "idle";

      systemd.services.nix-gc.serviceConfig.CPUSchedulingPolicy = "idle";

      # 0 will auto-detect the number of physical cores and use that
      nix.settings.build-cores = mkDefault 0;
    }
  ];
}
