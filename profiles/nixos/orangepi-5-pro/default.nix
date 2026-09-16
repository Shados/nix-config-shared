{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    # eMMC image generation, for initial flashing
    ./image.nix
    # Handles building and updating uboot
    ./uboot.nix
  ];

  # NOTE: Need at least Linux 7.3 to have the DTB for this SBC
  boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.kernelParams = [
    "console=ttyS2,1500000" # debug serial
    "console=tty1" # HDMI
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "sdhci_of_dwcmshc"
    "dw_mmc_rockchip"
  ];

  systemd.services.disable-blinkenlights = {
    wantedBy = [ "multi-user.target" ];
    description = "Disable default-heartbeat LEDs";
    serviceConfig.Type = "oneshot";
    script = ''
      echo none > /sys/class/leds/blue\:status/trigger
      echo none > /sys/class/leds/green\:activity/trigger
    '';
  };

  hardware.deviceTree = {
    enable = true;
    filter = "*rk3588s-orangepi-5-pro.dtb";
  };
}
