# Portable / USB installation setup
{ config, pkgs, ... }:

with pkgs.lib;
{
  imports = [ 
    <nixpkgs/nixos/modules/installer/scan/detected.nix>
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    <nixpkgs/nixos/modules/profiles/all-hardware.nix> # Full hardware support for... everything basically
    <nixpkgs/nixos/modules/profiles/base.nix> # minimal-installation-cd module, basically everything from there is useful here anyway
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
            echo "Root Delay = $rootDelay seconds"
            ;;
        esac
      done

      sleep $rootDelay # Force artificial boot delay
    '';
    initrd.availableKernelModules = [ "kvm-amd" "kvm-intel" ];
    initrd.kernelModules = [ "ahci" "ohci_pci" "ehci_pci" "xhci_pci" "usb_storage" "uas" "usbhid" "usbcore" "sd_mod" ];

    initrd.supportedFilesystems = [ "zfs" ]; # We may not always use zfs, but we assume we do because yeah.
    zfs.useGit = true;
    kernelParams = [ 
      "zfs.zfs_arc_max=536870912"  # Limit ZFS ARC size to 512MB max
      "boot.shell_on_fail"
      "rootdelay=1" # Seems we do actually need some level of root delay for usb enumeration to finish, in the real-world. 1s seems OK thus far...
    ];

    loader = {
      grub = {
        enable = true;
        efiSupport = mkDefault true;
        zfsSupport = true;
      };
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };

  # Building for quad-core systems as a sort of default - TODO: mkOverride appropriately?
  nix = {
    maxJobs = 4;
    buildCores = 4;
    nrBuildUsers = 16;
    daemonIONiceLevel = 7;
    daemonNiceLevel = 19;
  }; 
}
