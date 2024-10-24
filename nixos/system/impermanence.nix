{ config, lib, inputs, pkgs, ... }:
let
  inherit (lib) escapeShellArg mkAfter mkIf mkForce mkMerge mkOption optionalAttrs optionals singleton types;
  inherit (inputs.lib.fs) dsToBootFs dsToFs pristineSnapshot;

  usingZfs = config.boot.zfs.rootPool != null;
in
{
  options = {
    sn.statelessRoot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to use the impermanence flake to enforce a stateless root filesystem.
      '';
    };
  };
  config = mkIf config.sn.statelessRoot (mkMerge [
    # Default, baseline config
    {
      environment.persistence."/nix/persist" = {
        hideMounts = true;
        directories = [
          "/var/cron"
          "/var/lib"
          "/var/log"
        ] ++ optionals (! usingZfs) [
          "/srv"
        ];
        files = [
          "/etc/machine-id"
          "/etc/adjtime"
          "/etc/zfs/zpool.cache"
        ];
      };
      # Rather than persisting the file
      # TODO maybe move this to general config?
      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';
    }
    # ZFS-backed setup
    (mkIf usingZfs (let
      inherit (config.boot.zfs) rootPool rootDataset;
      abstractRoot = "${rootPool}/${config.boot.zfs.rootDataset}";
    in {
      fileSystems = {
        "/nix/persist" = dsToBootFs "${abstractRoot}/nix/persist";
        "/nix/persist/etc" = dsToBootFs "${abstractRoot}/nix/persist/etc";
        "/nix/persist/var" = dsToBootFs "${abstractRoot}/nix/persist/var";
        "/nix/persist/var/lib" = dsToBootFs "${abstractRoot}/nix/persist/var/lib";
        "/nix/persist/var/log" = dsToBootFs "${abstractRoot}/nix/persist/var/log";
        "/srv" = dsToFs "${abstractRoot}/srv";
      };
      boot.initrd.postResumeCommands = mkAfter ''
        echo "Rolling back root to pristine state"
        zfs rollback -r ${escapeShellArg config.fileSystems."/".device}@${escapeShellArg pristineSnapshot}
        echo "Rolling back tmp to pristine state"
        zfs rollback -r ${escapeShellArg config.fileSystems."/tmp".device}@${escapeShellArg pristineSnapshot}
      '';
      disk.fileSystems.zfs.pools.${rootPool}.datasets = {
        "HOMES/shados".postCreationMountHook = ''
          chown -R ${toString config.users.users.shados.uid}:${toString config.ids.gids.users} "$mountpoint"
        '';
        "${rootDataset}/tmp".postCreationHook = ''
          zfs snapshot "$dataset"@${escapeShellArg pristineSnapshot}
        '';
        "${rootDataset}/root" = {
          postCreationHook = ''
            zfs snapshot "$dataset"@${escapeShellArg pristineSnapshot}
          '';
          properties = {
            checksum = "skein";
            compression = "zle";
            sync = "disabled";
            "com.sun:auto-snapshot" = "false";
          };
        };
      };
      boot.tmp.cleanOnBoot = mkForce false;

      # Integrate with zfs-mount-generator
      environment.persistence."/nix/persist".directories = [
        "/etc/zfs/zfs-list.cache"
      ];
      # `postBootCommands` run prior to systemd starting, allowing us to ensure
      # the zfs-list.cache file for the root pool is in place prior to
      # zfs-mount-generator being invoked by systemd
      boot.postBootCommands = ''
        mkdir -p /etc/zfs/zfs-list.cache
        cp /nix/persist/etc/zfs/zfs-list.cache/* /etc/zfs/zfs-list.cache/
      '';
    }))
    # Integrations with various other modules
    (mkIf (config.boot.initrd.storeSecrets != {}) {
      environment.persistence."/nix/persist".directories = singleton config.boot.initrd.secretsDir;
    })
    (mkIf config.services.openssh.enable {
      environment.persistence."/nix/persist".files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    })
    (mkIf config.networking.networkmanager.enable {
      environment.persistence."/nix/persist".directories = singleton "/etc/NetworkManager/system-connections";
    })
  ]);
}
