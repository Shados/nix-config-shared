{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge;
in
{
  config = mkMerge [
    {
      # Fix issue in the wake of nixpkgs #336988
      systemd.services.dhcpcd.serviceConfig.ReadWritePaths = [ "/proc/sys/net/ipv4" ];
    }
    (mkIf config.services.mullvad-vpn.enable {
      systemd.services.mullvad-daemon.environment.TALPID_NET_CLS_MOUNT_DIR = "/run/mullvad-net-cls-v1";
    })
  ];
}
