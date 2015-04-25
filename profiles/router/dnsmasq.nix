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

  networking.firewall.extraCommands = lib.mkOrder 1000 ''
    # Add custom rules
    -A lan-fw -p tcp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 67 -j ACCEPT
    -A lan-fw -p udp --dport 68 -j ACCEPT
  '';
}
