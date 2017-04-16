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
        example = "input";
        type = types.str;
        description = "Name of the nftables chain.";
      };

      definition = mkOption {
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
    config = {
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
    config = {
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
    flush ruleset

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
              input = {
                definition = "type filter hook input priority 0; policy drop";
                rules = ''
                  # established/related connections
                  ct state established,related accept

                  # invalid connections
                  ct state invalid drop

                  # loopback interface
                  iif lo accept

                  # ICMP
                  # routers may also want: mld-listener-query, nd-router-solicit
                  ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
                  ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem } accept

                  # SSH (port 22)
                  tcp dport ssh accept

                  # HTTP (ports 80 & 443)
                  tcp dport {http, https} accept
                '';
              };
            };
          };
        };
      };
    })
  ];
}
