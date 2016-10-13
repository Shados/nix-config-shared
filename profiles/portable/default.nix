# Portable / USB installation setup
{ config, pkgs, ... }:

with pkgs.lib;
{
  # Import a bunch of stuff from the livecd/installer expressions, piggyback off of others' work :>
  imports = [
    <nixpkgs/nixos/modules/profiles/all-hardware.nix>

    # 'minimal' install cd software, basically all useful given usb installs often end up used for recovery/setup work anyway
    # NOTE: does set networking.hostId, so this needs to be mkForce'd elsewhere for it to be machine-specific
    <nixpkgs/nixos/modules/profiles/base.nix> 
  ];

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
      "zfs.zfs_arc_max=536870912"  # Limit ZFS ARC size to 512MB max by default, doesn't hurt for this usage and can be tweaked at boot anyway
      "boot.shell_on_fail"
      "rootdelay=1" # Seems we do actually need some level of root delay for usb enumeration to finish, in the real-world. 1s seems OK thus far...
    ];

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

  # Setup for quad-core systems as some sort of default, given what I usually end up booting this on
  nix = {
    maxJobs = mkDefault 4;
    buildCores = mkDefault 4;
  };
}
