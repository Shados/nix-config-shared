{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
in
{
  config = mkMerge [
    {
      boot.kernelParams = [
        # Disable spectre/meltdown/etc. mitigations for performance
        # improvements; browsers have their own mitigations anyway
        "mitigations=off"
        # Disable watchdogs, largely not needed on a desktop system
        "nowatchdog"
        # https://www.phoronix.com/news/Linux-Splitlock-Hurts-Gaming
        "split_lock_detect=off"
      ];
      boot.blacklistedKernelModules = [
        # AMD watchdog module
        "sp5100_tco"
      ];

      environment.systemPackages = with pkgs; [
        mangohud
        dualsensectl
      ];

      programs.gamescope.enable = true;
      # See nixpkgs issue #351516
      programs.gamescope.capSysNice = false;
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-cpp;
        extraRules = [
          {
            "name" = "gamescope";
            "nice" = -20;
          }
        ];
      };
      programs.gamemode = {
        enable = mkDefault true;
        settings = {
          general = {
            desiredgov = "schedutil";
            renice = 20;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            amd_performance_level = "high";
          };
          # custom = {
          #   start = "${pkgs.libnotify}/bin/notify-send -t 3000 'GameMode started'";
          #   end = "${pkgs.libnotify}/bin/notify-send -t 3000 'GameMode ended'";
          # };
        };
      };
      environment.variables = {
        GAMEMODERUNEXEC = mkIf config.programs.gamemode.enable "PROTON_WINEDBG_DISABLE=1 WINEDEBUG=-all";
      };
    }
  ];
}
