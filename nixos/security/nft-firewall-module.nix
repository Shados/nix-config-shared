# pingLimit semantics changed
# TODO: checkReversePath support... not entirely clear to be how to do this in nftables, 'fib' statement is somewhat under-documented but appears to be applicable
# TODO: Modify libvirtd to take libvirt package as a config option, so we can pass it an overrided version that uses iptables-compat and ebtables-compat from nftables package
# TODO: Look into docker compat issues
{ config, lib, pkgs, ... }:

with lib;
let
  fwcfg = config.networking.firewall;
  natcfg = config.networking.nat;
  cfg = config.networking.nft-firewall;

  chainOpts = { config, name, ... }: {
    options = {
      name = mkOption {
        example = "INPUT";
        type = types.str;
        description = "Name of the nftables chain.";
      };
      definition = mkOption {
        default = "";
        example = "type filter hook input priority 0;";
        type = types.str;
        description = "Defining properties of the chain.";
      };
      rules = mkOption {
        example = ''
          ct state established,related accept
          ct state invalid drop
        '';
        type = types.lines;
        description = "Rules to add to the chain.";
      };
    };
    config = { name = mkDefault name; };
  };

  mkFamilyOption = family: mkOption {
    default = {};
    type = with types; attrsOf (loaOf (submodule chainOpts));
    description = ''
      This option defines the nftables tables for the
      ${family} family.

      Each attribute of this set defines a single nftables
      table for this family, with the attribute defining
      the name of the table, and the contents being another
      attribute set.

      Each child attribute set defines a single nftables
      chain for the given table.
    '';
  };

  makeChain = name: chain: ''
    chain ${name} {
      ${chain.definition}

      ${chain.rules}
    }
  '';

  makeTable = family: tablename: table: ''
    table ${family} ${tablename} {
      ${concatMapStrings (chain: ''
        ${chain}
      '') (mapAttrsToList (makeChain) table)}
    }
  '';

  makeFamily = family: tables: ''
    ${concatMapStrings (famtables: ''
      ${famtables}
    '') (mapAttrsToList (makeTable family) tables)}
  '';


  ruleset = ''
    ${makeFamily "arp" cfg.arp}
    ${makeFamily "ip" cfg.ip}
    ${makeFamily "ip6" cfg.ip6}
    ${makeFamily "inet" cfg.inet}
    ${makeFamily "bridge" cfg.bridge}
    ${makeFamily "netdev" cfg.netdev}
  '';

  natDest = if natcfg.externalIP == null then "masquerade" else "snat ${natcfg.externalIP}";

  portsToNftSet = ports: portRanges: lib.concatStringsSep ", " (
    map (x: toString x) ports
    ++ map (x: "${toString x.from}-${toString x.to}") portRanges
  );
in

# table family > table name > chain name
# allow people to write both chain spec and rules free-form

{
  options = {
    networking.nft-firewall = {
      enable = mkEnableOption "nftables-based firewall";
      enableNAT = mkEnableOption "nftables-based NAT";
      enableDefaultRules = mkOption {
        default = true;
        example = false;
        description = "Whether to enable the default nftables-based firewall rules.";
        type = lib.types.bool;
      };

      arp = mkFamilyOption "arp";
      ip = mkFamilyOption "ip";
      ip6 = mkFamilyOption "ip6";
      inet = mkFamilyOption "inet";
      bridge = mkFamilyOption "bridge";
      netdev = mkFamilyOption "netdev";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Disable the default firewall & NAT implementations
      networking.firewall.enable = false;
      networking.firewall.trustedInterfaces = [ "lo" ];
      networking.nat.enable = false;

      environment.systemPackages = with pkgs; [ nftables ];
      networking.nftables.enable = true;
      networking.nftables.ruleset = ruleset;
    })
    (mkIf (cfg.enable && cfg.enableDefaultRules) {
      networking.nft-firewall = {
        inet = {
          filter = {
            nixos-fw-accept.rules = ''
              # This chain just accepts packets
              accept
            '';
            nixos-fw-refuse.rules = ''
              # This chain rejects or drops packets
              ${if fwcfg.rejectPackets then ''
                # Send a reset for existing TCP connections
                tcp flags != syn reject with tcp reset
                # Send ICMP 'port unreachable' for all else
                ip reject with icmp type port-unreachable
                ip6 reject with icmpv6 type port-unreachable
              '' else ''
                drop
              ''}
            '';
            nixos-fw-log-refuse.rules = ''
              # This chain optionally performs logging, then jumps to the
              # refuse chain
              ${optionalString fwcfg.logRefusedConnections ''
                tcp flags syn / fin,syn,rst,ack log level info prefix "refused connection: "
              ''}
              ${optionalString (fwcfg.logRefusedPackets && !fwcfg.logRefusedUnicastsOnly) ''
                meta pkttype broadcast log level info prefix "rejected broadcast: "
                meta pkttype multicast log level info prefix "rejected multicast: "
              ''}
              ${optionalString fwcfg.logRefusedPackets ''
                pkttype host log level info prefix "refused packet: "
              ''}
              jump nixos-fw-refuse
            '';
            nixos-fw.rules = mkMerge [
              (mkBefore ''
                ${optionalString (fwcfg.trustedInterfaces != []) ''
                  iifname { ${concatMapStringsSep ", " (int: "\"${int}\"") fwcfg.trustedInterfaces} } accept comment "trusted interfaces"
                ''}

                # Rate-limited ICMPv6 ping; has to be done prior to accepting
                # established/related flows or it won't be applied properly
                icmpv6 type { echo-request, echo-reply } meter icmpv6-echo { ip6 saddr & ffff:ffff:ffff:ffff:: limit rate over 4/second } counter drop comment "Drop suspiciously-high ping rate from single source /64"

                # Accept packets from established/related connections
                ct state established,related accept
                # NOTE: Some ICMPv6 types like NDP is untracked
                ct state vmap {
                  invalid : drop,
                  established : accept,
                  related : accept,
                  new : continue,
                  untracked: continue,
                }
              '')
              ''
                ${lib.concatStrings (lib.mapAttrsToList (iface: cfg:
                  let
                    ifaceExpr = lib.optionalString (iface != "default") "iifname ${iface}";
                    tcpSet = portsToNftSet fwcfg.allowedTCPPorts fwcfg.allowedTCPPortRanges;
                    udpSet = portsToNftSet fwcfg.allowedUDPPorts fwcfg.allowedUDPPortRanges;
                  in
                  ''
                    ${lib.optionalString (tcpSet != "") "${ifaceExpr} tcp dport { ${tcpSet} } accept"}
                    ${lib.optionalString (udpSet != "") "${ifaceExpr} udp dport { ${udpSet} } accept"}
                  ''
                ) fwcfg.allInterfaces)}

                ${lib.optionalString fwcfg.allowPing ''
                  icmp type echo-request ${optionalString (fwcfg.pingLimit != null) "meter icmpv4-echo { ip saddr limit rate ${fwcfg.pingLimit} }"} accept comment "allow ping"
                ''}

                # ICMPv6 handling based on RFC 4890, generic for both transit
                # and local traffic
                icmpv6 type != { router-renumbering, 137, 139, 140 } accept comment "See RFC 4890, sections 4.3 and 4.4."

                ip6 daddr fe80::/64 udp dport 546 accept comment "DHCPv6 client"
              ''

              (mkAfter ''
                # Reject/drop everything else
                jump nixos-fw-log-refuse
              '')
            ];
            INPUT = {
              definition = "type filter hook input priority 0; policy drop";
              rules = mkAfter ''
                # Enable NixOS' default firewall
                jump nixos-fw
              '';
            };
          };
        };
      };
    })
    (mkIf (cfg.enable && cfg.enableNAT) {
      networking.nft-firewall = {
        ip.nat = {
          nixos-nat-pre.rules = ''
            # Mark packets coming from the internal interface(s)
            ${concatMapStrings (iface: ''
              meta iifname "${iface}" mark set 0x01
            '') natcfg.internalInterfaces}

            # NAT from external ports to internal ports
            ${concatMapStrings (fwd: ''
              meta iifname ${natcfg.externalInterface} tcp dport ${toString fwd.sourcePort} dnat ${fwd.destination}
            '') natcfg.forwardPorts}
          '';
          nixos-nat-post.rules = ''
            # NAT marked packets
            ${optionalString (natcfg.internalInterfaces != []) ''
              meta mark 0x01 oifname ${natcfg.externalInterface} ${natDest}
            ''}

            # NAT packets coming from the internal IPs
            ${concatMapStrings (range: ''
              ip saddr ${range} meta oifname ${natcfg.externalInterface} ${natDest}
            '') natcfg.internalIPs}
          '';
          PREROUTING = {
            definition = "type nat hook prerouting priority 0;";
            rules = ''
              jump nixos-nat-pre
            '';
          };
          POSTROUTING = {
            definition = "type nat hook postrouting priority 0;";
            rules = ''
              jump nixos-nat-post
            '';
          };
        };
      };
      boot = {
        kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = mkOverride 99 true;
          "net.ipv4.conf.default.forwarding" = mkOverride 99 true;
        };
      };
    })
    (mkIf (cfg.enable && config.virtualisation.libvirtd.enable) {
      assertions = [
        { assertion = config.boot.kernel.sysctl."net.ipv4.conf.all.forwarding" && config.boot.kernel.sysctl."net.ipv4.conf.default.forwarding";
          message = ''boot.kernel.sysctl."net.ipv4.conf.all.forwarding" and boot.kernel.sysctl."net.ipv4.conf.default.forwarding" must both be enabled if you want to use libvirtd NAT networking'';
        }
      ];
      # Trigger libvirtd restarts whenever nftables is started or reloaded
      systemd.services.nftables.serviceConfig.ExecStartPost = pkgs.writeScript "libvirtd-restart" ''
        #!${pkgs.runtimeShell} -e
        if systemctl is-active libvirtd.service; then
          systemctl restart libvirtd.service || true
        fi
      '';
      systemd.services.nftables.serviceConfig.ExecReload =  mkForce pkgs.writeScript "nftables-reload" ''
        #!${pkgs.runtimeShell} -e
        ${config.systemd.services.nftables.serviceConfig.ExecStart}

        if systemctl is-active libvirtd.service; then
          systemctl restart libvirtd.service || true
        fi
      '';
      # TODO once we know how to get libvirtd to reload firewall rules from
      # scratch without requiring a restart:
      #systemd.services.nftables.serviceConfig.ExecReload = let
      #  rulesScript = pkgs.writeScript "nftables-rules" ''
      #    #! ${pkgs.nftables}/bin/nft -f
      #    flush ruleset
      #    include "${config.networking.nftables.rulesetFile}"
      #  '';
      #  checkScript = pkgs.writeScript "nftables-check" ''
      #    #! ${pkgs.runtimeShell} -e
      #    if $(${pkgs.kmod}/bin/lsmod | grep -q ip_tables); then
      #      echo "Unload ip_tables before using nftables!" 1>&2
      #      exit 1
      #    else
      #      ${rulesScript}
      #    fi

      #    systemctl reload libvirtd.service || true
      #  '';
      #in mkForce checkScript;
      #systemd.services.nftables.serviceConfig.ExecStartPost = "systemctl reload libvirtd.service";
      #systemd.services.libvirtd = let
      #  configFile = pkgs.writeText "libvirtd.conf" ''
      #    auth_unix_ro = "polkit"
      #    auth_unix_rw = "polkit"
      #    ${config.virtualisation.libvirtd.extraConfig}
      #  '';
      #in {
      #  environment.LIBVIRTD_ARGS = mkForce (escapeShellArgs ([
      #    "--config" configFile
      #  ] ++ config.virtualisation.libvirtd.extraOptions));
      #  restartTriggers = [ configFile ];
      #};
    })
  ];
}
