{ config, pkgs, ... }:

{
  networking.sn-firewall.enable = false;
  networking.firewall = {
    enable = false;
    allowPing = true;
    connectionTrackingModules = [];
    autoLoadConntrackHelpers = false;
  };
}
