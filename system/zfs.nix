{ config, lib, pkgs, ... }:
with lib;
let
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
  };

  config = mkMerge [
    {
      services.zfs.trim.interval = "Mon *-*-* 03:30:00";
    }
    # TODO Only enable if zfs is in use; NixOS has a way of determining this in the zfs module
    (mkIf (cfg.scheduler != null) {
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
