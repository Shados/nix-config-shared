{ config, pkgs, ... }:

let 
  cfg = config.fragments.router;
in

pkgs.lib.mkIf (config.fragments.router.enable) {
  services.dnsmasq = {
    enable = true;
    servers = config.networking.nameservers;
    extraConfig = ''
      interface=${cfg.intBridge}
      dhcp-range=${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 0)},${cfg.intSubnet + "." + toString (builtins.elemAt cfg.dhcpRange 1)},12h
    '';
  };

  networking.firewall.extraCommands = ''
    # Add custom rules
    -A sn-fw -i ${cfg.intBridge} -j lan-fw
    -A lan-fw -p tcp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 53 -j ACCEPT
    -A lan-fw -p udp --dport 67 -j ACCEPT
    -A lan-fw -p udp --dport 68 -j ACCEPT
    -A lan-fw -j RETURN
  '';
}
