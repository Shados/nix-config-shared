{ config, pkgs, lib, ... }:

let 
  cfg = config.fragments.router;
in
with lib;

{
  config = mkIf (cfg.enable) {
    networking.firewall = {
      checkReversePath = false; # RP filtering on the bridge breaks broadcast packets due to reasons - TODO: Figure out why. TODO: Implement custom workaround.
    };
    networking.nft-firewall = {
      enable = true;
      enableNAT = true;
      inet.filter.lan-fw.rules = mkAfter ''
        return
      '';
      inet.filter.INPUT.rules = mkBefore ''
        meta iifname ${cfg.intBridge} jump lan-fw
      '';
      ip.nat.PREROUTING.rules = ''
        meta iifname ${cfg.extInt} jump lan-fw-forwards
      '';
      ip.nat.lan-fw-forwards.rules = ''
        ${concatMapStrings (pf: let portArg =
        if pf.sourcePort != null then toString pf.sourcePort
        else toString pf.portRange.from + "-" + toString pf.portRange.to; 
        in ''
          meta iifname ${cfg.extInt} ${pf.protocol} dport ${portArg} dnat ${pf.destAddr}
        '') cfg.portForwards}
      '';
    };
  };
}

# TODO: Upstream sn-firewall implementation
#   - TODO: Deal with things like libvirt that add iptables rules of their own
#   - TODO: Deal with adding custom rules to non-'filter' tables
#   - 
#   - 
