{
  buildUBoot,
  armTrustedFirmwareRK3588,
  rkbin,
  fetchpatch,
}:
(buildUBoot {
  defconfig = "orangepi-5-pro-rk3588s_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  env = {
    BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
    ROCKCHIP_TPL = rkbin.TPL_RK3588;
  };
  filesToInstall = [
    "u-boot.itb"
    "u-boot.dtb"
    "idbloader.img"
    "u-boot-rockchip.bin"
    "u-boot-rockchip-spi.bin"
  ];
  extraConfig = ''
    CONFIG_MMC_WRITE=y

    CONFIG_ENV_IS_IN_MMC=y
    CONFIG_ENV_MMC_DEVICE_INDEX=0
    # Use the first eMMC hardware boot partition to store u-boot's environment variables
    CONFIG_ENV_MMC_EMMC_HW_PARTITION=1
    # 256 KB
    CONFIG_ENV_SIZE=0x40000
    CONFIG_ENV_REDUNDANT=y
    # Setting these two to the same value while having CONFIG_ENV_MMC_EMMC_HW_PARTITION set results in the redundant variables being stored in the *second* eMMC hardware boot partition
    # 4MB - 256KB
    CONFIG_ENV_OFFSET=0x3C0000
    CONFIG_ENV_OFFSET_REDUND=0x3C0000

    # Do *not* fall back to trying to store the environment "nowhere" on a CRC failure during loading the env
    CONFIG_ENV_IS_NOWHERE=n
    # Save the current environment to persistent storage before continuing with the default bootflow
    CONFIG_BOOTCOMMAND="env save; bootflow scan -lb"
    # The combination of the above two results in saving the default config to persistent storage on first boot, when there would be no valid config in storage
  '';
  extraPatches = [
    (fetchpatch {
      url = "https://github.com/armbian/build/raw/refs/heads/main/patch/u-boot/v2025.10/board_orangepi5pro/0001-rockchip-rk3588-Add-support-for-the-OrangePI-5-Pro.patch";
      hash = "sha256-Dtfo6nOFvKfdyOES7qDPDyJ/26LNj1gOzAsAouUQr6c=";
    })
    (fetchpatch {
      url = "https://github.com/armbian/build/raw/refs/heads/main/patch/u-boot/v2025.10/board_orangepi5pro/0002-net-dwc_eth_qos-Add-support-for-Motorcomm-YT6801.patch";
      hash = "sha256-xwPTUXtlSWVuF+Q04aWwxo+UasQeTmUab6D2dpymoyo=";
    })
    (fetchpatch {
      url = "https://github.com/armbian/build/raw/refs/heads/main/patch/u-boot/v2025.10/board_orangepi5pro/0003-net-dwc_eth_qos-Allow-overriding-descriptor-size-and.patch";
      hash = "sha256-kzKwORh0qRyK3yvhX7crqpW6OPTqLhgjQmX8NX4FwxI=";
    })
    (fetchpatch {
      url = "https://github.com/armbian/build/raw/refs/heads/main/patch/u-boot/v2025.10/board_orangepi5pro/0004-rockchip-board-Skip-MAC-address-setup-for-Orange-Pi-.patch";
      hash = "sha256-ILZixVjcSS3H2KGCTX/8DyhgeNT8wHzZDs1aSY1DS/E=";
    })
  ];
}).overrideAttrs
  (oa: {
    # Remove duplicate lines introduced by the first patch in the set
    postPatch = oa.postPatch or "" + ''
      sed -i '1670,1699d' dts/upstream/src/arm64/rockchip/rk3588-base.dtsi
    '';
  })
