{ config, pkgs, lib, ... }:

let
  cfg = config.fragments.router;
  natcfg = config.networking.nat;
  natDest = if natcfg.externalIP == null then "masquerade" else "snat ${natcfg.externalIP}";
in
with lib;

{
  config = mkMerge [
    (mkIf (cfg.enable) {
      networking.nat.enable = true;
      networking.nftables = {
        enable = true;
        ruleset = ''
          table ip nat {
            chain PREROUTING {
              type nat hook prerouting priority filter; policy accept;

              # Drop packets that come from outside but claim to be from within the LAN
              ${concatMapStrings (addr: ''
                ip saddr ${addr} meta iifname ${cfg.extInt} drop
              '') natcfg.internalIPs}
            }
            chain POSTROUTING {
              type nat hook postrouting priority filter; policy accept;

              ${concatMapStrings (pf: let
              portArg =
                if pf.sourcePort != null then toString pf.sourcePort
                else toString pf.portRange.from + "-" + toString pf.portRange.to;
              destPort = 
                if pf.destPort != null then toString pf.destPort
                else toString portArg;
              in ''
                # SNAT as part of hairpin NAT (LAN-to-LAN NAT)
                meta oifname ${cfg.intBridge} ip saddr { ${concatStringsSep ", " natcfg.internalIPs } } ip daddr ${pf.destAddr} ${pf.protocol} dport ${destPort} ${natDest}
              '') cfg.portForwards}
            }
          }
        '';
      };
      # RP filtering on the bridge breaks broadcast packets due to reasons
      # - TODO Figure out why.
      # - TODO Implement custom workaround.
      networking.firewall.checkReversePath = false;
    })
    # Port forwards with NAT reflection
    (mkIf ((natcfg.externalIP != null) && cfg.enable) {
      networking.nftables.ruleset = ''
        table ip nat {
          chain PREROUTING {
            # Port forward packets aimed at the external IP address, regardless of what interface they come from
            ${concatMapStrings (pf: let
            portArg =
              if pf.sourcePort != null then toString pf.sourcePort
              else toString pf.portRange.from + "-" + toString pf.portRange.to;
            destAddr =
              if pf.destPort != null then "${pf.destAddr}:${toString pf.destPort}"
              else pf.destAddr;
            in ''
              ip daddr ${natcfg.externalIP} ${pf.protocol} dport ${portArg} dnat ${destAddr}
            '') cfg.portForwards}
          }
        }
      '';
    })
    (mkIf ((natcfg.externalIP == null) && cfg.enable) {
      networking.nftables.ruleset = ''
        table ip nat {
          chain PREROUTING {
            # Port forward packets aimed at local addresses (read: any address assigned to an interface) that aren't a LAN ip (ergo, only WAN IPs)
            ${concatMapStrings (pf: let
            portArg =
              if pf.sourcePort != null then toString pf.sourcePort
              else toString pf.portRange.from + "-" + toString pf.portRange.to;
            destAddr =
              if pf.destPort != null then "${pf.destAddr}:${toString pf.destPort}"
              else pf.destAddr;
            in ''
              fib daddr type local ip daddr != { ${concatStringsSep ", " natcfg.internalIPs} } ${pf.protocol} dport ${portArg} dnat ${destAddr}
            '') cfg.portForwards}
          }
        }
      '';
    })
  ];
}

# TODO: Upstream sn-firewall implementation
#   - TODO: Deal with things like libvirt that add iptables rules of their own
#   - TODO: Deal with adding custom rules to non-'filter' tables
