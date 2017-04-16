{ config, pkgs, lib, ... }:

let 
  cfg = config.fragments.router;
in

lib.mkIf (config.fragments.router.enable) {
  services.dnsmasq = {
    enable = true;
    servers = config.networking.nameservers;
    extraConfig = ''
      interface=${cfg.intBridge}
      dhcp-range=${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 0)},${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 1)},12h
    '';
  };

  networking.nft-firewall.inet.filter.lan-fw.rules = lib.mkOrder 1000 ''
    tcp dport 53 accept
    udp dport { 53, 67, 68} accept
  '';


  # TODO: Nov 13 20:55:49 l1.shados.net dnsmasq[22485]: dnsmasq: cannot open or create lease file /var/lib/misc/dnsmasq.leases: No such file or directory 
}
