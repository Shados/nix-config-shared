{ config, lib, pkgs, ... }:

with lib;

let 

  cfg = config.networking.sn-firewall;
  fwcfg = config.networking.firewall;
  natcfg = config.networking.nat;

  kernelPackages = config.boot.kernelPackages;
  kernelHasRPFilter = kernelPackages.kernel.features.netfilterRPFilter or false;
  kernelCanDisableHelpers = kernelPackages.kernel.features.canDisableNetfilterConntrackHelpers or false;

  dest = if natcfg.externalIP == null then "-j MASQUERADE" else "-j SNAT --to-source ${natcfg.externalIP}";

  stopScript = pkgs.writeText "iptables-flush.sh" ''
    #!/bin/sh
    ${pkgs.iptables}/sbin/iptables -P INPUT ACCEPT
    ${pkgs.iptables}/sbin/iptables -P FORWARD ACCEPT
    ${pkgs.iptables}/sbin/iptables -P OUTPUT ACCEPT
    ${pkgs.iptables}/sbin/iptables -t nat -F
    ${pkgs.iptables}/sbin/iptables -t mangle -F
    ${pkgs.iptables}/sbin/iptables -F
    ${pkgs.iptables}/sbin/iptables -X
  '';

  iptables_rules = pkgs.writeText "iptables.rules" ''
    *filter

    -P INPUT DROP
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT

    -N sn-fw-accept
    -A sn-fw-accept -j ACCEPT

    -N sn-fw-refuse
    ${if fwcfg.rejectPackets then ''
      -A sn-fw-refuse -p tcp ! --syn -j REJECT --reject-with tcp-reset
      -A sn-fw-refuse -j REJECT
    '' else ''
      -A sn-fw-refuse -j DROP
    ''}

    -N sn-fw-log-refuse
    ${optionalString fwcfg.logRefusedConnections ''
      -A sn-fw-log-refuse -p tcp --syn -j LOG --log-level info --log-prefix "rejected connection: "
    ''}
    ${optionalString (fwcfg.logRefusedPackets && !fwcfg.logRefusedUnicastsOnly) ''
      -A sn-fw-log-refuse -m pkttype --pkt-type broadcast -j LOG --log-level info --log-prefix "rejected broadcast: "
      -A sn-fw-log-refuse -m pkttype --pkt-type multicast -j LOG --log-level info --log-prefix "rejected multicast: "
    ''}
    -A sn-fw-log-refuse -j sn-fw-refuse

    -N sn-fw

    ${flip concatMapStrings fwcfg.trustedInterfaces (iface: ''
      -A sn-fw -i ${iface} -j sn-fw-accept
    '')}

    -A sn-fw -m conntrack --ctstate ESTABLISHED,RELATED -j sn-fw-accept

    ${concatMapStrings (port: ''
      -A sn-fw -p tcp --dport ${toString port} -j sn-fw-accept
    '') fwcfg.allowedTCPPorts }

    ${concatMapStrings (port: ''
      -A sn-fw -p udp --dport ${toString port} -j sn-fw-accept
    '') fwcfg.allowedUDPPorts }

    ${concatMapStrings (rangeAttr:
      let range = toString rangeAttr.from + ":" + toString rangeAttr.to; in ''
      -A sn-fw -p tcp --dport ${range} -j sn-fw-accept
    '') fwcfg.allowedTCPPortRanges }

    ${concatMapStrings (rangeAttr:
      let range = toString rangeAttr.from + ":" + toString rangeAttr.to; in ''
      -A sn-fw -p udp --dport ${range} -j sn-fw-accept
    '') fwcfg.allowedUDPPortRanges }

    ${optionalString fwcfg.allowPing ''
      -A sn-fw -p icmp --icmp-type echo-request ${optionalString (fwcfg.pingLimit != null) "-m limit ${fwcfg.pingLimit} "} -j sn-fw-accept
    ''}


    ${fwcfg.extraCommands}

    -A sn-fw -j sn-fw-log-refuse
    -A INPUT -j sn-fw

    COMMIT

    *raw
    ${optionalString (kernelHasRPFilter && fwcfg.checkReversePath) ''
      -A PREROUTING -m rpfilter --invert -j DROP
    ''}
    COMMIT

    ${optionalString cfg.enable_nat ''
      *nat
      ${concatMapStrings (iface: ''
        -A PREROUTING -i '${iface}' -j MARK --set-mark 1
      '') natcfg.internalInterfaces }

      ${optionalString (natcfg.internalInterfaces != []) ''
        -A POSTROUTING -m mark --mark 1 -o ${natcfg.externalInterface} ${dest}
      ''}

      ${concatMapStrings (range: ''
        -A POSTROUTING -s ${range} -o ${natcfg.externalInterface} ${dest}
      '') natcfg.internalIPs }

      COMMIT
    ''}
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

    };
  };

  ##### implementation

  config = mkIf cfg.enable {
    # Disable the default firewall & NAT implementations
    networking.firewall.enable = false;
    networking.nat.enable = false;

    networking.firewall.trustedInterfaces = [ "lo" ];

    environment.systemPackages = [ pkgs.iptables ];

    boot.kernelModules = map (x: "nf_conntrack_${x}") fwcfg.connectionTrackingModules ++ [ "nf_nat_ftp" ];
    boot.kernel.sysctl = if cfg.enable_nat then { "net.ipv4.ip_forward" = true; } else {};
    boot.extraModprobeConfig = optionalString (!fwcfg.autoLoadConntrackHelpers) ''
      options nf_conntrack nf_conntrack_helper=0
      '';

    assertions = [
    { assertion = ! fwcfg.checkReversePath || kernelHasRPFilter;
      message = "This kernel does not support rpfilter"; }
    { assertion = fwcfg.autoLoadConntrackHelpers || kernelCanDisableHelpers;
      message = "This kernel does not support disabling conntrack helpers"; }
    ];

    systemd.services.firewall =
    { description = "ShadosNet custom firewall service implementation";

      wantedBy = [ "network.target" ];
      #after = [ "network-interfaces.target" "systemd-modules-load.service" ];
      after = [ "systemd-modules-load.service" ];
      before = [ "network-interfaces.target" ];

      path = [ pkgs.iptables ];

      # FIXME: this module may also try to load kernel modules, but
      # containers don't have CAP_SYS_MODULE. So the host system had
      # better have all necessary modules already loaded.
      unitConfig.ConditionCapability = "CAP_NET_ADMIN";

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iptables}/sbin/iptables-restore ${iptables_rules}";
        ExecReload = "${pkgs.iptables}/sbin/iptables-restore ${iptables_rules}";
        ExecStop = "/bin/sh ${stopScript}";
      }; 
    };

  };

}
