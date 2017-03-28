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

  networking.sn-firewall.v4rules.filter = lib.mkOrder 1000 ''
    # Add custom rules
    -A lan-fw -p tcp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 67 -j ACCEPT
    -A lan-fw -p udp --dport 68 -j ACCEPT
  '';


  # TODO: Nov 13 20:55:49 l1.shados.net dnsmasq[22485]: dnsmasq: cannot open or create lease file /var/lib/misc/dnsmasq.leases: No such file or directory 
}
