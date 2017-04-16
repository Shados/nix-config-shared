# pingLimit semantics changed
# TODO: Modify libvirtd to take libvirt package as a config option, so we can pass it an overrided version that uses iptables-compat and ebtables-compat from nftables package
# TODO: checkReversePath support
{ config, lib, pkgs, ... }:

with lib;
let
  fwcfg = config.networking.firewall;
  natcfg = config.networking.nat;
  cfg = config.networking.nft-firewall;

  parentConfig = config;
  chainOpts = { config, name, ... }: let cfg = config; in let config = parentConfig; in {
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
  };

  tableOpts = { config, name, ... }: let cfg = config; in let config = parentConfig; in {
    options = {
      name = mkOption {
        example = "filter";
        type = types.str;
        description = "Name of the nftables table.";
      };

      chains = mkOption {
        default = [];
        type = with types; loaOf (submodule chainOpts);
        description = ''
          This option defines the nftables chains for the given table.

          Each attribute of this set defines a single nftables chain
          for this table, with the attribute defining the name of the
          chain.
        '';
      };
    };
  };

  mkFamilyOption = family: mkOption {
    default = [];
    type = with types; loaOf (submodule tableOpts);
    description = ''
      This option defines the nftables tables for the
      ${family} family.

      Each attribute of this set defines a single nftables
      table for this family, with the attribute defining
      the name of the table.
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
      '') (mapAttrsToList (makeChain) table.chains)}
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
in

# table family > table name > chain name
# allow people to write both chain spec and rules free-form

{
  options = {
    networking.nft-firewall = {
      enable = mkEnableOption "nftables-based firewall";
      enableDefaultRules = mkEnableOption "default firewall rules";

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
    (mkIf cfg.enableDefaultRules {
      networking.nft-firewall = {
        inet = {
          filter = {
            chains = {
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
                # This chain optionally performs logging, then 
                # jumps to the refuse chain
                ${optionalString fwcfg.logRefusedConnections ''
                  tcp flags syn log level info prefix "rejected connection: "
                ''}
                ${optionalString (fwcfg.logRefusedPackets && !fwcfg.logRefusedUnicastsOnly) ''
                  meta pkttype broadcast log level info prefix "rejected broadcast: "
                  meta pkttype multicast log level info prefix "rejected multicast: "
                  meta pkttype != unicast jump nixos-fw-refuse
                ''}
                ${optionalString fwcfg.logRefusedPackets ''
                  log level info prefix "rejected packet: "
                ''}
                jump nixos-fw-refuse
              '';
              nixos-fw.rules = ''
                # Accept all traffic on the trusted interfaces
                ${flip concatMapStrings fwcfg.trustedInterfaces (iface: ''
                  meta iifname "${iface}" jump nixos-fw-accept
                '')}

                # Accept packets from established/related connections
                ct state established,related accept

                # Accept connections to allowed TCP ports
                ${concatMapStrings (port: ''
                  tcp dport ${toString port} jump nixos-fw-accept
                '') fwcfg.allowedTCPPorts}

                # Accept connections to allowed TCP port ranges
                ${concatMapStrings (rangeAttr:
                  let range = toString rangeAttr.from + "-" + toString rangeAttr.to; in ''
                  tcp dport ${range} jump nixos-fw-accept
                '') fwcfg.allowedTCPPortRanges}

                # Accept connections to allowed UDP ports
                ${concatMapStrings (port: ''
                  udp dport ${toString port} jump nixos-fw-accept
                '') fwcfg.allowedUDPPorts}

                # Accept connections to allowed UDP port ranges
                ${concatMapStrings (rangeAttr:
                  let range = toString rangeAttr.from + "-" + toString rangeAttr.to; in ''
                  udp dport ${range} jump nixos-fw-accept
                '') fwcfg.allowedUDPPortRanges}

                # Optionally respond to ICMPv4 pings
                ${optionalString fwcfg.allowPing ''
                  ip6 nexthdr icmpv6 icmpv6 type echo-request ${optionalString (fwcfg.pingLimit != null) "limit rate ${fwcfg.pingLimit}"} accept
                  ip protocol icmp icmp type echo-request ${optionalString (fwcfg.pingLimit != null) "limit rate ${fwcfg.pingLimit}"} accept
                ''}

                # Filter rules

                # Reject/drop everything else
                jump nixos-fw-log-refuse
              '';
              INPUT = {
                definition = "type filter hook input priority 0; policy drop";
                rules = ''
                  # Enable NixOS' default firewall
                  jump nixos-fw
                '';
              };
            };
          };
        };
      };
    })
  ];
}
