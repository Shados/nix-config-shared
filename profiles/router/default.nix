{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.fragments.router;

  portRange = { config, ... }: {
    options = {
      from = mkOption {
        example = 10;
        type = types.int;
        description = "Start of port range to forward from.";
      };
      to = mkOption {
        example = 20;
        type = types.int;
        description = "End of port range to forward from.";
      };
    };
  };
  portForwardOpts = { config, ... }: {
    options = {
      sourcePort = mkOption {
        example = 25565;
        type = with types; nullOr int;
        description = "Source port to be forwarded from.";
        default = null;
      };
      portRange = mkOption {
        example = { from = 10; to = 20; };
        type = with types; nullOr (submodule portRange);
        description = "Port range to forward form.";
        default = null;
      };
      destAddr = mkOption {
        example = "192.168.0.108";
        type = types.str;
        description = "Destination address to be forwarded to.";
      };
      destPort = mkOption {
        example = 25565;
        type = with types; nullOr int;
        description = "Destination port to be forwarded to.";
        default = null;
      };
      protocol = mkOption {
        example = "tcp";
        type = types.str;
        description = "Protocol of the port to be forwarded.";
      };
    };
  };
in

{
  # TODO: LAN, Bridging, Firewall (NAT), DNS, DHCPD, transparent caching?, traffic shaping, bandwidth limiting, QoS
  imports = [
    # Hostapd module extension
    ./hostapd-module.nix
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
          List of internal (LAN) network interfaces, these will be bridged together. Excludes the wifi interface, if any.
        '';
        example = [ "enp2s0" "enp3s0" ];
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
      enableWifi = mkOption {
        description = ''
          Whether or not to enable the wifi AP support.
        '';
        default = true;
        type = types.bool;
      };
      wifiInt = mkOption {
        description = ''
          Wireless network interface to configure & use.
        '';
        example = "wlp3s0";
        type = types.nullOr types.str;
      };
      wifiSSID = mkOption {
        description = ''
          Wireless network SSID to use.
        '';
        example = "SN-Test";
        type = types.nullOr types.str;
      };
      wifiPassphrase = mkOption {
        description = ''
          Wireless network WPA2 passphrase to use.
        '';
        example = "mysekret";
        type = types.nullOr types.str;
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
      enableBridge = mkOption {
        description = ''
          Whether or not to enable constructing a bridge from the internal interfaces.
        '';
        default = true;
        type = types.bool;
      };
      portForwards = mkOption {
        description = "List of port forwards to enable.";
        type = with types; listOf (submodule portForwardOpts);
        default = [];
      };
    };
  };
}
