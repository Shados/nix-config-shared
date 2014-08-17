{ config, pkgs, ... }:

with pkgs.lib;

let 

  cfg = config.fragments.router;

in

{
  # TODO: LAN, Bridging, Firewall (NAT), DNS, DHCPD, transparent caching?, traffic shaping, bandwidth limiting, QoS
  imports = [
    # Sets up the hostapd access point
    ./wireless-ap.nix
    # Sets up network details (bridges, IP addresses, routes, NAT details)
    ./network.nix
    # DNS & DHCPD
    ./dnsmasq.nix
    # Firewall configuration
    ./firewall.nix
  ];

  options = {
    fragments.router = {
      enable = mkOption {
        description = ''
          Whether or not to enable the SN basic-router implementation.
        '';
        default = false;
        type = types.bool;
      };
      extInt = mkOption {
        description = ''
          External (WAN) network interface. Bond them if you have multiples.
        '';
        example = "enp1s0";
        type = types.str;
      };
      intInts = mkOption {
        description = ''
          List of internal (LAN) network interfaces, these will be bridged together.
        '';
        example = [ "enp2s0" "wlp3s0" ];
        type = types.listOf types.str;
      };
      intBridge = mkOption {
        description = ''
          Name to use for the internal (LAN) bridge.
        '';
        example = "lan0";
        default = "lan0";
        type = types.str;
      };
      wifiInt = mkOption {
        description = ''
          Wireless network interface to configure & use.
        '';
        example = "wlp3s0";
        type = types.str;
      };
      wifiSSID = mkOption {
        description = ''
          Wireless network SSID to use.
        '';
        example = "SN-Test";
        type = types.str;
      };
      wifiPassphrase = mkOption {
        description = ''
          Wireless network WPA2 passphrase to use.
        '';
        example = "mysekret";
        type = types.str;
      };
      intSubnet = mkOption {
        description = ''
          LAN subnet for the router itself, specified as first 3 octets (we assume a /24 for simplicity's sake).
        '';
        example = "192.168.8";
        default = "192.168.8";
        type = types.str;
      };
      dhcpRange = mkOption {
        description = ''
          LAN DHCP range, specified as a list of two numbers (start and end last-octets).
        '';
        example = [ 100 150 ];
        default = [ 100 150 ];
        type = types.listOf types.int;
      };
    };
  };
}