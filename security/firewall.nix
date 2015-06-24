{ config, pkgs, ... }:

{
  networking.sn-firewall.enable = false;
  networking.firewall = {
    enable = true;
    allowPing = true;
    connectionTrackingModules = [];
    autoLoadConntrackHelpers = false;
  };
  environment.systemPackages = with pkgs; [ iptables ];
}
