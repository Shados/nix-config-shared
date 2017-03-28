{ config, lib, pkgs, ... }:

with lib;

let

  sncfg = config.networking.sn-firewall;
  cfg = config.networking.firewall;
  natcfg = config.networking.nat;

  kernelPackages = config.boot.kernelPackages;
  kernelHasRPFilter = kernelPackages.kernel.features.netfilterRPFilter or false;
  kernelCanDisableHelpers = kernelPackages.kernel.features.canDisableNetfilterConntrackHelpers or false;

  dest = if natcfg.externalIP == null then "-j MASQUERADE" else "-j SNAT --to-source ${natcfg.externalIP}";

  iptables_reset_rules = pkgs.writeText "iptables-reset.rules" ''
    # Resets every table to default state (all ACCEPT), and removes all custom chains
    *filter
    :INPUT ACCEPT
    :FORWARD ACCEPT
    :OUTPUT ACCEPT
    COMMIT

    *mangle
    :PREROUTING ACCEPT
    :INPUT ACCEPT
    :FORWARD ACCEPT
    :OUTPUT ACCEPT
    :POSTROUTING ACCEPT 
    COMMIT

    *raw
    :PREROUTING ACCEPT
    :OUTPUT ACCEPT
    COMMIT

    *security
    :INPUT ACCEPT
    :FORWARD ACCEPT
    :OUTPUT ACCEPT
    COMMIT
  '';

  iptables_v4_rules = pkgs.substituteAll {
    name = "iptables-v4.rules";
    src = iptables_generic_rules;
    pingRules = ''
      # Optionally respond to ICMPv4 pings.
      ${optionalString cfg.allowPing ''
        -A nixos-fw -p icmp --icmp-type echo-request ${optionalString (cfg.pingLimit != null) "-m limit ${cfg.pingLimit} "} -j nixos-fw-accept
      ''}
    '';
    filterRules = if (sncfg.v4rules.filter != "") then sncfg.v4rules.filter else "";
    mangleRules = if (sncfg.v4rules.mangle != "") then ''
      *mangle
      ${sncfg.v4rules.mangle} 
      COMMIT
    '' else "";
    rawRules = if (sncfg.v4rules.raw != "") then ''
      *raw
      ${sncfg.v4rules.raw}
      COMMIT
    '' else "";
    securityRules = if (sncfg.v4rules.security != "") then ''
      *security
      ${sncfg.v4rules.security}
      COMMIT
    '' else "";
  };
  iptables_v6_rules = pkgs.substituteAll {
    name = "iptables-v6.rules";
    src = iptables_generic_rules;
    pingRules = ''
      # Accept all ICMPv6 messages except redirects and node
      # information queries (type 139).  See RFC 4890, section
      # 4.4.
      -A nixos-fw -p icmpv6 --icmpv6-type redirect -j DROP
      -A nixos-fw -p icmpv6 --icmpv6-type 139 -j DROP
      -A nixos-fw -p icmpv6 -j nixos-fw-accept
    '';
    filterRules = if (sncfg.v6rules.filter != "") then sncfg.v6rules.filter else "";
    mangleRules = if (sncfg.v6rules.mangle != "") then ''
      *mangle
      ${sncfg.v6rules.mangle} 
      COMMIT
    '' else "";
    rawRules = if (sncfg.v6rules.raw != "") then ''
      *raw
      ${sncfg.v6rules.raw}
      COMMIT
    '' else "";
    securityRules = if (sncfg.v6rules.security != "") then ''
      *security
      ${sncfg.v6rules.security}
      COMMIT
    '' else "";
  };

  iptables_generic_rules = pkgs.writeText "iptables-generic.rules" ''
    *filter

    -P INPUT DROP

    # The "nixos-fw-accept" chain just accepts packets.
    -N nixos-fw-accept
    -A nixos-fw-accept -j ACCEPT


    # The "nixos-fw-refuse" chain rejects or drops packets.
    -N nixos-fw-refuse

    ${if cfg.rejectPackets then ''
      # Send a reset for existing TCP connections that we've
      # somehow forgotten about.  Send ICMP "port unreachable"
      # for everything else.
      -A nixos-fw-refuse -p tcp ! --syn -j REJECT --reject-with tcp-reset
      -A nixos-fw-refuse -j REJECT
    '' else ''
      -A nixos-fw-refuse -j DROP
    ''}


    # The "nixos-fw-log-refuse" chain performs logging, then
    # jumps to the "nixos-fw-refuse" chain.
    -N nixos-fw-log-refuse

    ${optionalString cfg.logRefusedConnections ''
      -A nixos-fw-log-refuse -p tcp --syn -j LOG --log-level info --log-prefix "rejected connection: "
    ''}
    ${optionalString (cfg.logRefusedPackets && !cfg.logRefusedUnicastsOnly) ''
      -A nixos-fw-log-refuse -m pkttype --pkt-type broadcast -j LOG --log-level info --log-prefix "rejected broadcast: "
      -A nixos-fw-log-refuse -m pkttype --pkt-type multicast -j LOG --log-level info --log-prefix "rejected multicast: "
    ''}
    -A nixos-fw-log-refuse -m pkttype ! --pkt-type unicast -j nixos-fw-refuse
    ${optionalString cfg.logRefusedPackets ''
      -A nixos-fw-log-refuse \
        -j LOG --log-level info --log-prefix "rejected packet: "
    ''}
    -A nixos-fw-log-refuse -j nixos-fw-refuse


    # The "nixos-fw" chain does the actual work.
    -N nixos-fw

    # Perform a reverse-path test to refuse spoofers
    # For now, we just drop, as the raw table doesn't have a log-refuse yet
    ${flip concatMapStrings cfg.trustedInterfaces (iface: ''
      -A nixos-fw -i ${iface} -j nixos-fw-accept
    '')}

    # Accept all traffic on the trusted interfaces.
    ${flip concatMapStrings cfg.trustedInterfaces (iface: ''
      -A nixos-fw -i ${iface} -j nixos-fw-accept
    '')}

    # Accept packets from established or related connections.
    -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept

    # Accept connections to the allowed TCP ports.
    ${concatMapStrings (port: ''
      -A nixos-fw -p tcp --dport ${toString port} -j nixos-fw-accept
    '') cfg.allowedTCPPorts }

    # Accept connections to the allowed TCP port ranges.
    ${concatMapStrings (rangeAttr:
      let range = toString rangeAttr.from + ":" + toString rangeAttr.to; in ''
      -A nixos-fw -p tcp --dport ${range} -j nixos-fw-accept
    '') cfg.allowedTCPPortRanges }

    # Accept packets on the allowed UDP ports.
    ${concatMapStrings (port: ''
      -A nixos-fw -p udp --dport ${toString port} -j nixos-fw-accept
    '') cfg.allowedUDPPorts }

    # Accept packets on the allowed UDP port ranges.
    ${concatMapStrings (rangeAttr:
      let range = toString rangeAttr.from + ":" + toString rangeAttr.to; in ''
      -A nixos-fw -p udp --dport ${range} -j nixos-fw-accept
    '') cfg.allowedUDPPortRanges }

    @pingRules@

    @filterRules@

    # Reject/drop everything else.
    -A nixos-fw -j nixos-fw-log-refuse

    # Put the firewall chain into use
    -A INPUT -j nixos-fw

    COMMIT


    @mangleRules@

    @rawRules@

    @securityRules@
  '';

  tableOpts = {
    filter = mkOption {
      type = types.lines;
      default = "";
      example = "-A INPUT -p icmp -j ACCEPT";
      description = ''
        Additional iptables rules added to the iptables-restore file
        as part of the filter table rules.
        These are added just before the final "reject" firewall rule 
        is added, so they can be used to allow packets that would 
        otherwise be refused.
      '';
    };
    nat = mkOption {
      type = types.lines;
      default = "";
      example = "-A INPUT -p icmp -j ACCEPT";
      description = ''
        Additional iptables rules added to the iptables-restore file
        as part of the nat table rules.
      '';
    };
    mangle = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional iptables rules added to the iptables-restore file
        as part of the mangle table rules.
      '';
    };
    raw = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional iptables rules added to the iptables-restore file
        as part of the raw table rules.
      '';
    };
    security = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional iptables rules added to the iptables-restore file
        as part of the security table rules.
      '';
    };
  };

  iptables_reset_nat_rules = pkgs.writeText "iptables-reset-nat.rules" ''
    *nat
    :PREROUTING ACCEPT
    :INPUT ACCEPT
    :OUTPUT ACCEPT
    :POSTROUTING ACCEPT
    COMMIT
  '';
  iptables_nat_v4_rules = pkgs.substituteAll {
    name = "ipv4-nat.rules";
    src = iptables_generic_nat_rules;
    natRules = if (sncfg.v4rules.nat != "") then sncfg.v4rules.nat else "";
  };
 iptables_nat_v6_rules = pkgs.writeText "blank.rules" "";
 # TODO: v6 support
 #iptables_nat_v6_rules = pkgs.substituteAll {
 #  name = "iptables-nat-v6rules.rules";
 #  src = iptables_generic_nat_rules;
 #  natRules = if (sncfg.v6rules.nat != "") then sncfg.v6rules.nat else "";
 #};

  iptables_generic_nat_rules = pkgs.writeText "iptables-generic-nat.rules" ''
    *nat
    ${optionalString sncfg.enable_nat ''
      ${concatMapStrings (iface: ''
        # We can't match on incoming interface in POSTROUTING, so
        # mark packets coming from the external interfaces.
        -A PREROUTING -i '${iface}' -j MARK --set-mark 1
      '') natcfg.internalInterfaces }

      ${optionalString (natcfg.internalInterfaces != []) ''
        # NAT the marked packets.
        -A POSTROUTING -m mark --mark 1 -o ${natcfg.externalInterface} ${dest}
      ''}

      ${concatMapStrings (range: ''
        # NAT packets coming from the internal IPs.
        -A POSTROUTING -s ${range} -o ${natcfg.externalInterface} ${dest}
      '') natcfg.internalIPs }
    ''}

    @natRules@

    COMMIT
  '';

  flushNat = ''
    iptables -w -t nat -D PREROUTING -j nixos-nat-pre 2>/dev/null|| true
    iptables -w -t nat -F nixos-nat-pre 2>/dev/null || true
    iptables -w -t nat -X nixos-nat-pre 2>/dev/null || true
    iptables -w -t nat -D POSTROUTING -j nixos-nat-post 2>/dev/null || true
    iptables -w -t nat -F nixos-nat-post 2>/dev/null || true
    iptables -w -t nat -X nixos-nat-post 2>/dev/null || true
  '';

  setupNat = ''
    # Create subchain where we store rules
    iptables -w -t nat -N nixos-nat-pre
    iptables -w -t nat -N nixos-nat-post

    # We can't match on incoming interface in POSTROUTING, so
    # mark packets coming from the external interfaces.
    ${concatMapStrings (iface: ''
      iptables -w -t nat -A nixos-nat-pre \
        -i '${iface}' -j MARK --set-mark 1
    '') natcfg.internalInterfaces}

    # NAT the marked packets.
    ${optionalString (natcfg.internalInterfaces != []) ''
      iptables -w -t nat -A nixos-nat-post -m mark --mark 1 \
        -o ${natcfg.externalInterface} ${dest}
    ''}

    # NAT packets coming from the internal IPs.
    ${concatMapStrings (range: ''
      iptables -w -t nat -A nixos-nat-post \
        -s '${range}' -o ${natcfg.externalInterface} ${dest}
    '') natcfg.internalIPs}

    # NAT from external ports to internal ports.
    ${concatMapStrings (fwd: ''
      iptables -w -t nat -A nixos-nat-pre \
        -i ${natcfg.externalInterface} -p tcp \
        --dport ${builtins.toString fwd.sourcePort} \
        -j DNAT --to-destination ${fwd.destination}
    '') natcfg.forwardPorts}

    # Append our chains to the nat tables
    iptables -w -t nat -A PREROUTING -j nixos-nat-pre
    iptables -w -t nat -A POSTROUTING -j nixos-nat-post
  '';

in

{

  ##### interface

  options = {

    networking.sn-firewall = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the custom SN firewall implementation.
        '';
      };

      enable_nat = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the custom SN NAT implementation.
        '';
      };

      v4rules = tableOpts;
      v6rules = tableOpts;
    };
  };

  ##### implementation

  config = mkMerge [
    (mkIf (sncfg.enable) {
      # Disable the default firewall & NAT implementations
      networking.firewall.enable = false;
      networking.nat.enable = false;

      networking.firewall.trustedInterfaces = [ "lo" ];

      networking.sn-firewall = {
        v4rules.raw = mkBefore (optionalString (kernelHasRPFilter && cfg.checkReversePath) ''
          -A PREROUTING -m rpfilter --invert -j DROP
        '');
        v6rules.raw = mkBefore (optionalString (kernelHasRPFilter && cfg.checkReversePath) ''
          -A PREROUTING -m rpfilter --invert -j DROP
        '');
      };

      environment.systemPackages = [ pkgs.iptables ];

      boot.kernelModules = map (x: "nf_conntrack_${x}") cfg.connectionTrackingModules ++ [ "nf_nat_ftp" ];
      boot.kernel.sysctl = if sncfg.enable_nat then { "net.ipv4.ip_forward" = true; } else {};

      systemd.services.firewall =
      { description = "ShadosNet custom firewall service implementation";

        wantedBy = [ "sysinit.target" ];
        wants = [ "network-pre.target" ];
        after = [ "systemd-modules-load.service" ];
        before = [ "network-interfaces.target" "network-pre.target" ];

        path = [ pkgs.iptables pkgs.ipset ];

        # FIXME: this module may also try to load kernel modules, but
        # containers don't have CAP_SYS_MODULE. So the host system had
        # better have all necessary modules already loaded.
        unitConfig.ConditionCapability = "CAP_NET_ADMIN";
        reloadIfChanged = true; # Needed for atomic firewall updates

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_v4_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_v6_rules}"
          ];
          ExecReload = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_v4_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_v6_rules}"
          ];
          ExecStop = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_reset_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_reset_rules}"
          ];
        };
      };
    })
    (mkIf (sncfg.enable_nat) {
      systemd.services.nat = {
        description = "Network Address Translation";

        wantedBy = [ "sysinit.target" ];
        wants = [ "network-pre.target" ];
        after = [ "systemd-modules-load.service" ];
        before = [ "network-interfaces.target" "network-pre.target" ];

        path = [ pkgs.iptables ];
        reloadIfChanged = true; # Needed for atomic firewall updates

        preStart = ''
          echo 1 > /proc/sys/net/ipv4/ip_forward
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_nat_v4_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_nat_v6_rules}"
          ];
          ExecReload = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_nat_v4_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_nat_v6_rules}"
          ];
          ExecStop = [
            "${pkgs.iptables}/sbin/iptables-restore ${iptables_reset_nat_rules}"
            "${pkgs.iptables}/sbin/ip6tables-restore ${iptables_reset_nat_rules}"
          ];
        };
      };
    })
  ];
}
