# System configuration changes
{ config, lib, pkgs, system, ... }:
with lib;
let
  cfg = config.fragments;
in
{
  imports = [
    ./builders.nix
    ./disk
    ./fish
    ./fonts.nix
    ./graphical.nix
    ./haveged.nix
    ./impermanence.nix
    ./initrd-secrets.nix
    ./memory.nix
    ./networking.nix
    ./nix.nix
    ./smtp.nix
    ./ssh
    ./tpm2.nix
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
      # TODO: hm equivalent config, for darwin only
      programs.command-not-found.enable = false;
      programs.nix-index = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
      };
      programs.nix-index-database.comma.enable = true;
      environment.shellInit = ''
        for dir in $HOME/technotheca/artifacts/packages/bin $HOME/technotheca/packages/bin; do
          if [[ -d $dir ]]; then
            export PATH="$dir''${PATH:+:''${PATH}}"
          fi
        done
      '';
      boot.kernel.sysctl."kernel.panic" = mkDefault 10; # Reboot after 10s on panic
    }
    (mkIf config.documentation.nixos.enable {
      environment.systemPackages = with pkgs; [
        nix-help
        nixpkgs-help
      ];
    })
    { # Disable coredump creation, collection, and storage
      # Main with systemd-coredumpd: it doesn't¹ do streaming compression, it
      # first writes out the dump file in full and then reads that to write a
      # compressed version. Given it is passed the coredump from the kernel as
      # a *stream* on stdin, this is fucking *absurd*, particularly when
      # coredumps tend to be extremely compressible (100x is not uncommon!) and
      # disk writes tend to be slow.
      # As a result, its process of capturing coredumps is significnatly slower
      # and more resource-intensive (in IO and memory consumption) than it
      # otherwise needs to be, which I've seen lead to e.g. coredump collection
      # triggering OOM killer, coredump collection delaying service restarts
      # massively (see below issue).
      systemd.coredump.enable = mkDefault false;

      # Main issue with systemd and having coredumps enabled at all: the
      # service won't be recognised as stopped until the fd passed to the
      # coredump handler is fully read or closed, delaying service restart
      # until that point. This is primarily a result of the kernel interface
      # being quite naff: really, the kernel *could* just remap the coredump
      # memory into the memory space of the coredump handler, along with the
      # process info and then immediately reap the process without blocking.
      # This would remove some unnecessary memory copying and make process
      # reaping behaviour much more consistent across both the "coredumps
      # enabled" and "coredumps disabled" cases.
      # Unfortunately, it does not, so we explicitly disable coredumps
      # entirely. If we need to debug things, we can explicitly re-enable them
      # on a case-by-case basis.
      boot.kernel.sysctl."kernel.core_pattern" = mkOverride 900 "";
      boot.kernel.sysctl."kernel.core_uses_pid" = mkDefault 0;

      # 1: It does do streaming compression under some very torturous
      # conditions if and only if you're storing coredumps in tmpfs. Fuck that
      # noise.
    }
    (mkIf cfg.remote {
      console.keyMap = ./sn.map.gz;
    })
    {
      boot.tmp.cleanOnBoot = true;

      # Internationalisation & localization properties.
      console.font   = mkOverride 999 "lat9w-16";
      i18n = {
        defaultLocale = "en_AU.UTF-8";
        extraLocaleSettings = {
          # Set the fallback locales
          LANGUAGE = "en_AU:en_GB:en_US:en";
          # Keep the default sort order (e.g. files starting with a '.' should
          # appear at the start of a directory listing)
          LC_COLLATE = "C.UTF-8";
          # yyyy-mm-dd date format :D
          LC_TIME = "en_DK.UTF-8";
        };
      };
      time.timeZone = "Australia/Melbourne";

      documentation.nixos = {
        enable = true;
        includeAllModules = false;
      };
    }
  ];
}
