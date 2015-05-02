{ config, pkgs, lib, ... }:

lib.mkIf config.fragments.readahead.enable {
  # Kernel customization
  boot.kernelPackages = pkgs.linuxPackages_3_19;
  nixpkgs.config.packageOverrides = pkgs: {
    linux_3_19 = pkgs.linux_3_19.override {
      extraConfig =
        ''
          # Required for systemd-readahead support
          FANOTIFY y
        '';
    };
  };
}
