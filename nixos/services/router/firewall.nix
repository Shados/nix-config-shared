{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.fragments.router;
  natcfg = config.networking.nat;
  natDest = if natcfg.externalIP == null then "masquerade" else "snat ${natcfg.externalIP}";
in
with lib;

{
  config = mkMerge [
    (mkIf (cfg.enable) {
      networking.firewall = {
        # RP filtering on the bridge breaks broadcast packets due to reasons
        # - TODO Figure out why.
        # - TODO Implement custom workaround.
        checkReversePath = false;
      };
      networking.nft-firewall = {
        enable = true;
        enableNAT = true;
        # Setup lan-specific firewall chain
        inet.filter.INPUT.rules = mkBefore ''
          meta iifname ${cfg.intBridge} jump lan-fw
        '';
        inet.filter.lan-fw.rules = mkAfter ''
          return # Return back to the main chain when we're done
        '';
        ip.nat = {
          PREROUTING.rules = ''
            jump lan-fw-nat-pre
          '';
          INPUT.rules = "";
          OUTPUT.rules = "";
          POSTROUTING.rules = ''
            jump lan-fw-nat-post
          '';
          lan-fw-nat-pre.rules = mkBefore ''
            # Drop packets that come from outside but claim to be from within the LAN
            ${concatMapStrings (addr: ''
              ip saddr ${addr} meta iifname ${cfg.extInt} drop
            '') natcfg.internalIPs}
          '';
          lan-fw-nat-post.rules = ''
            ${concatMapStrings (
              pf:
              let
                portArg =
                  if pf.sourcePort != null then
                    toString pf.sourcePort
                  else
                    toString pf.portRange.from + "-" + toString pf.portRange.to;
                destPort = if pf.destPort != null then toString pf.destPort else toString portArg;
              in
              ''
                # SNAT as part of hairpin NAT (LAN-to-LAN NAT)
                meta oifname ${cfg.intBridge} ip saddr { ${concatStringsSep ", " natcfg.internalIPs} } ip daddr ${pf.destAddr} ${pf.protocol} dport ${destPort} ${natDest}
              ''
            ) cfg.portForwards}
          '';
        };
      };
    })
    # Port forwards with NAT reflection
    (mkIf ((natcfg.externalIP != null) && cfg.enable) {
      networking.nft-firewall.ip.nat = {
        lan-fw-nat-pre.rules = ''
          # Port forward packets aimed at the external IP address, regardless of what interface they come from
          ${concatMapStrings (
            pf:
            let
              portArg =
                if pf.sourcePort != null then
                  toString pf.sourcePort
                else
                  toString pf.portRange.from + "-" + toString pf.portRange.to;
              destAddr = if pf.destPort != null then "${pf.destAddr}:${toString pf.destPort}" else pf.destAddr;
            in
            ''
              ip daddr ${natcfg.externalIP} ${pf.protocol} dport ${portArg} dnat ${destAddr}
            ''
          ) cfg.portForwards}
        '';
      };
    })
    (mkIf ((natcfg.externalIP == null) && cfg.enable) {
      networking.nft-firewall.ip.nat = {
        lan-fw-nat-pre.rules = ''
          # Port forward packets aimed at local addresses (read: any address assigned to an interface) that aren't a LAN ip (ergo, only WAN IPs)
          ${concatMapStrings (
            pf:
            let
              portArg =
                if pf.sourcePort != null then
                  toString pf.sourcePort
                else
                  toString pf.portRange.from + "-" + toString pf.portRange.to;
              destAddr = if pf.destPort != null then "${pf.destAddr}:${toString pf.destPort}" else pf.destAddr;
            in
            ''
              fib daddr type local ip daddr != { ${concatStringsSep ", " natcfg.internalIPs} } ${pf.protocol} dport ${portArg} dnat ${destAddr}
            ''
          ) cfg.portForwards}
        '';
      };
    })
  ];
}

# TODO: Upstream sn-firewall implementation
#   - TODO: Deal with things like libvirt that add iptables rules of their own
#   - TODO: Deal with adding custom rules to non-'filter' tables
