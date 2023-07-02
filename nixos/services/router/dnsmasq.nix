{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.fragments.router;
in
mkIf (cfg.enable && cfg.enableDhcp) {
  services.dnsmasq = {
    enable = true;
    settings = let
      staticDevs = filter (host: host.mac != null) (attrValues config.registry.network);
    in {
      server = config.networking.nameservers;
      interface = "${cfg.intBridge}";
      dhcp-range = "${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 0)},${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 1)},12h";
      # https://serverfault.com/questions/255487/excessive-dhcp-requests-in-var-log-messages-dhcpinform-dhcpack-and-dhcpreques
      dhcp-option = "252,\"\\n\"";
      # Static DHCP leases based on MAC addresses
      dhcp-host = flip map staticDevs (host: "${host.mac},${host.ipv4}");
    };
  };

  networking.nft-firewall.inet.filter.lan-fw.rules = ''
    tcp dport 53 accept
    udp dport {53, 67, 68} accept
  '';
}
