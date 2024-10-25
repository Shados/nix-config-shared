{ config, inputs, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
  ];
  # Fix issue in the wake of nixpkgs #336988
  systemd.services.dhcpcd.serviceConfig.ReadWritePaths = [ "/proc/sys/net/ipv4" ];
}
