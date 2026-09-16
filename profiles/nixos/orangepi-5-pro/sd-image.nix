# Stand-alone config for generic aarch64 SD image modified to boot properly on an Orange Pi 5 Pro
{
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  ubootPackage = pkgs.callPackage ./uboot-package.nix { };
in
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix")
  ];
  sdImage.postBuildCommands = ''
    echo "Writing u-boot to the image"
    dd conv=notrunc if=${ubootPackage}/u-boot-rockchip.bin of=$img seek=64
  '';
  # NOTE: Need at least Linux 7.3 to have the DTB for this SBC
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
  boot.kernelParams = lib.mkBefore [
    "console=ttyS2,1500000" # debug serial
    "console=tty1" # HDMI
  ];
  boot.supportedFilesystems = [
    "bcachefs"
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
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.registry.nixpkgs = {
    exact = true;
    flake = inputs.nixpkgs;
  };
}
