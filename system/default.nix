# System configuration changes
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.fragments;
in
{
  imports = [
    ./backup.nix
    ./builders.nix
    ./config-snapshot.nix
    ./disk
    ./do-init
    ./fish
    ./fonts.nix
    ./graphical.nix
    ./haveged.nix
    ./memory.nix
    ./networking.nix
    ./nix.nix
    ./smtp.nix
    ./sound.nix
    ./ssh
    ./systemd.nix
    ./users.nix
    ./zfs.nix
  ];

  options = {
  };

  config = mkMerge [
    {
      boot.kernelParams = mkIf (! config.fragments.remote) [ "boot.shell_on_fail" ];
      environment.sessionVariables.TERMINFO = pkgs.lib.mkDefault "/run/current-system/sw/share/terminfo"; # TODO: the fish bug that needed this may now be fixed, should test
      environment.sessionVariables.EDITOR = "nvim";
      services.locate.enable = false;
      services.logind.extraConfig = ''
        KillUserProcesses=no
      '';
      systemd.enableEmergencyMode = mkDefault false;
      services.zfs.autoScrub = {
        enable = true;
        interval = "Mon 05:00";
      };
    }
    (mkIf config.documentation.nixos.enable {
      environment.systemPackages = with pkgs; [
        # nix-help # FIXME un-break this
        nixpkgs-help
      ];
    })
    (mkIf cfg.remote {
      console.keyMap = ./sn.map.gz;
    })
    {
      boot.cleanTmpDir = true;

      # Internationalisation & localization properties.
      console.font   = mkOverride 999 "lat9w-16";
      i18n = {
        defaultLocale = "en_US.UTF-8";
      };
      time.timeZone = "Australia/Melbourne";

      documentation.nixos = {
        enable = mkDefault true;
        # Disabled until nixpkgs issue #90124 is resolved
        # includeAllModules = true;
      };
    }
    { # Workaround for openzfs/zfs issue #9810
      boot.kernelParams = mkIf config.boot.zfs.enabled [ "spl.spl_taskq_thread_dynamic=0" ];
    }
  ];
}
