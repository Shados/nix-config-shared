{ config, pkgs, lib, ... }:

lib.mkIf config.fragments.readahead.enable {
  # Kernel customization
  boot.kernelPackages = pkgs.linuxPackages_3_15;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_3_15 = pkgs.linux_3_15.override {
      extraConfig =
        ''
          # Required for systemd-readahead support
          FANOTIFY y
        '';
    };
  };
}
