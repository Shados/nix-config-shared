# Portable / USB installation setup
{ config, lib, modulesPath, pkgs, ... }:

with lib;
let
  cfg = config.profiles.portable;
in
{
  # Import a bunch of stuff from the livecd/installer expressions, piggyback off of others' work :>
  imports = [
    "${modulesPath}/profiles/all-hardware.nix"
    # 'minimal' install cd software, basically all useful given usb installs often end up used for recovery/setup work anyway
    # NOTE: does set networking.hostId, so this needs to be mkForce'd elsewhere for it to be machine-specific
    "${modulesPath}/profiles/base.nix"
  ];

  options = {
    profiles.portable = {
      zfsMemoryLimit = mkOption {
        description = ''
          Amount of RAM to limit ZFS to using for the ARC, in bytes. Set to 0
          to disable.

          Defaults to 512MB.
        '';
        type = types.int;
        default = 536870912;
      };
    };
  };

  config = {
    # Stuff needed to boot
    boot = {
      # Support kernel-cmdline-configurable root-mounting-delay
      initrd.postDeviceCommands = pkgs.lib.mkBefore ''
        rootDelay=0
        for o in $(cat /proc/cmdline); do
          case $o in
            rootdelay=*)
              set -- $(IFS==; echo $o)
              rootDelay=$2
              ;;
          esac
        done

        echo "Sleeping for Root Delay = $rootDelay seconds"
        sleep $rootDelay # Force artificial boot delay
      '';

      initrd.kernelModules = [ "ohci_pci" "ehci_pci" "xhci_pci" "uas" "sd_mod" ];

      initrd.supportedFilesystems = [ "zfs" ]; # When don't I use zfs these days?

      kernelParams = [
        "boot.shell_on_fail"
        "rootdelay=1" # Seems we do actually need some level of root delay for usb enumeration to finish, in the real-world. 1s seems OK thus far...
      ] ++ optional (cfg.zfsMemoryLimit > 0) "zfs.zfs_arc_max=${toString cfg.zfsMemoryLimit}";

      loader = {
        # NOTE: Still need to set grub.device elsewhere if we're supporting BIOS booting as well
        grub = {
          enable = true;
          efiSupport = mkDefault true;
          zfsSupport = true;
        };
        efi = {
          canTouchEfiVariables = false;
          efiSysMountPoint = "/boot";
        };
      };
    };

    nix = {
      maxJobs = mkDefault 8;
    };
  };
}
