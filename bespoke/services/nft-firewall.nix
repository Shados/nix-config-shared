{ config, lib, pkgs, ... }:

with lib;
let
  fwcfg = config.networking.firewall;
  natcfg = config.networking.nat;
  cfg = config.networking.nft-firewall;
in

# Firewall options to support:
# allowPing
# allowedTCPPortRanges
# allowedTCPPorts
# allowedUDPPortRanges
# allowedUDPPorts
# checkReversePath
# extraCommands?
# logRefusedConnections
# logRefusedPackets
# logRefusedUnicastsOnly
# logReversePathDrops
# pingLimit
# rejectPackets # icmp instead of drop
# trustedInterfaces

# NAT interface:
# externalIP
# externalInterface
# forwardPorts
# internalIPs
# internalInterfaces


# Interface ideas:
# table type > type name > chain?

{
  options = {
    networking.nft-firewall = {
      enable = mkEnableOption "nftables-based firewall";
    };
  };

  config = {
    # Disable the default firewall & NAT implementations
    networking.firewall.enable = false;
    networking.nat.enable = false;

    environment.systemPackages = with pkggs; [ nftables ];
    networking.nftables.ruleset = ''
      flush ruleset

      table inet filter {
        chain input {
          type filter hook priority 0; policy drop;

          # established/related connections
          ct state established,related accept

          # invalid connections
          ct state invalid drop

          # loopback interface
          iif lo accept

          # ICMP
          # routers may also want: mld-listener-query, nd-router-solicit
          ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbour-solicit, nd-neighbour-advert } accept
          ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem } accept

          # SSH (port 22)
          tcp dport ssh accept

          # HTTP (ports 80 & 443)
          tcp dport {http, https} accept
        }
      }
    '';
  };
}
