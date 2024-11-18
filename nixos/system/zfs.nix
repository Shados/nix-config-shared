{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (inputs.lib.fs) dsToBootFs dsToFs pristineSnapshot;
  cfg = config.boot.zfs;
in
{
  options = {
    boot.zfs.scheduler = mkOption {
      type = with types; nullOr str;
      default = "none";
      description = ''
        Scheduler to set for disks with any ZFS partitions (even if they *also*
        have non-ZFS partitions). Set to `null` to disable.

        NOTE: ZFS on Linux configures the scheduler for disks with whole-disk
        ZFS partitions to `none`, so that it may perform its own IO scheduling
        unmolested. However, for disks that have some non-ZFS partitions (e.g.
        an EFI system partition to boot from), ZoL will not configure the IO
        scheduler, hence this option.
      '';
    };
    boot.zfs.rootPool = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        If root is hosted on a ZFS pool, this must be set to the name of
        the pool.
      '';
    };
    boot.zfs.rootDataset = mkOption {
      type = with types; str;
      default = "ROOTS/nixos";
      description = ''
        If root is hosted on a ZFS pool, this must be set to the path to the
        dataset which should contain this NixOS installation, which I'll call
        the 'abstract root'. You must also set `boot.zfs.rootPool` in order
        for this to function.

        Preconditions on the abstract root:
        - `mountpoint` property must be `none`; the abstract root dataset is
          not the *actual* root and is instead used as a container for a single
          NixOS system's system-level datasets
        - The `/nix` sub-dataset must exist and have `mountpoint=/nix`, to
          contain the Nix store

        If using in combination with `sn.statelessRoot = true`, additional
        preconditions apply:
        - The `/root` sub-dataset must exist, have `mountpoint=/`, and have a
          snapshot called `${pristineSnapshot}` with absolutely no
          contents, to facilitate fast reset to that blank state on each boot.
        - The `/tmp` sub-dataset must exist, have `mountpoint=/tmp`, and have a
          snapshot called `${pristineSnapshot}` with absolutely no
          contents, to facilitate fast reset to that blank state on each boot.

        Note that the stateless root module does not persist `/home`, so
        unless user home(s) are on a separate dataset or filesystem, they
        will be ephemeral.
      '';
    };
  };

  config = mkMerge [
    {
      services.zfs.trim = {
        interval = "Mon 03:30";
        randomizedDelaySec = "0";
      };
      services.zfs.autoScrub = {
        enable = true;
        interval = "Mon 05:00";
        randomizedDelaySec = "0";
      };
    }
    { # Workaround for openzfs/zfs issue #9810
      boot.kernelParams = mkIf config.boot.zfs.enabled [ "spl.spl_taskq_thread_dynamic=0" ];
    }
    # Use zfs-mount-generator instead of zfs-mount.service
    # NOTE: Somewhat experimental systemd-mount-generator setup, based on a
    # comment in nixpkgs #62644, appears to solve nixpkgs #212762
    (mkIf (cfg.rootPool != null) (let
      inherit (cfg) rootPool;
    in {
      systemd.tmpfiles.rules = [
        #Type Path                                                    Mode User Group Age         Argument
        "f    /etc/zfs/zfs-list.cache/${rootPool}                        0644 root root  -           -"
      ];
      systemd.generators."zfs-mount-generator" = "${config.boot.zfs.package}/lib/systemd/system-generator/zfs-mount-generator";
      environment.etc."zfs/zed.d/history_event-zfs-list-cacher.sh".source = "${config.boot.zfs.package}/etc/zfs/zed.d/history_event-zfs-list-cacher.sh";
      systemd.services.zfs-mount.enable = false;

      # NOTE: Have to fully re-define because this is a string value, no way to
      # simply add diffutils to the front of the list, and can't re-use the
      # default without hitting infinite recursion... might be nice if the
      # module system exposed a `.default` attribute for options, maybe?
      services.zfs.zed.settings.PATH = lib.mkForce (lib.makeBinPath [
        pkgs.diffutils
        config.boot.zfs.package
        pkgs.coreutils
        pkgs.curl
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
        pkgs.nettools
        pkgs.util-linux
      ]);
    }))

    # No-sync /tmp instead of tmpfs
    (mkIf (cfg.rootPool != null) (let
      inherit (cfg) rootPool rootDataset;
    in {
      boot.tmp.cleanOnBoot = true;
      boot.tmp.useTmpfs = false;
      fileSystems."/tmp" = dsToFs "${rootPool}/${rootDataset}/tmp";
      disk.fileSystems.zfs.pools.${rootPool}.datasets."${rootDataset}/tmp".properties = {
        checksum = "skein";
        compression = "zle";
        sync = "disabled";
        devices = false;
        setuid = false;
        "com.sun:auto-snapshot" = "false";
      };
    }))

    (mkIf (cfg.enabled && cfg.scheduler != null) {
      # TODO use libzutil's `zfs_dev_is_whole_disk` and only apply scheduler to
      # disks that don't have it set by ZoL directly?
      services.udev.extraRules = ''
        # Use a PROGRAM to match on disks that contain *any* zfs partitions, and
        # set their scheduler to noop/none
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="${cfg.scheduler}", PROGRAM="${pkgs.writers.writeBash "zfsmatch" ''
          # Cheap test first, expensive test second
          if [[ $ID_FS_TYPE == zfs_member ]]; then
            exit 0
          elif [[ $(${pkgs.utillinux}/bin/blkid -s 'TYPE' "$DEVNAME"*) =~ zfs_member ]]; then
            exit 0
          else
            exit 1
          fi
        ''}"
      '';
    })
  ];
}
