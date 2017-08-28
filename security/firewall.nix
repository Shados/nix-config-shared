{ config, pkgs, ... }:

with pkgs.lib;

{
  networking.sn-firewall.enable = mkDefault false;
  networking.firewall = {
    enable = mkDefault true;
    allowPing = true;
    connectionTrackingModules = [];
    autoLoadConntrackHelpers = false;
  };
  environment.systemPackages = with pkgs; [ iptables ]; # TODO: change this when I get around to upstreaming the nftables-based firewall module, as we'll want iptables-compat instead
}
