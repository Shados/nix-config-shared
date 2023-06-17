# Notes
chains are unique based on table<>chain-name tuple, not on table<>chain-name<>chain-type

Table types:
```
arp
ip
ip6
inet (ip/ip6 dual)
bridge
netdev
```

Chain details:
```
# types
filter # arp/bridge/ip/ip6/inet
route # ip/ip6 only, mark packets. mangle for output hook, filter for other hooks
nat # ip/ip6 only, for doing NAT

# hooks
ip/ip6/inet: prerouting, input, forward, output, postrouting
arp: input, output
bridge: handles ethernet packets traversing bridge devices (TODO: the fuck are the hooks for it?)
netdev: ingress

# priority
refers to a number used to order the chains or to set them between some Netfilter operations. Possible values are: NF_IP_PRI_CONNTRACK_DEFRAG (-400), NF_IP_PRI_RAW (-300), NF_IP_PRI_SELINUX_FIRST (-225), NF_IP_PRI_CONNTRACK (-200), NF_IP_PRI_MANGLE (-150), NF_IP_PRI_NAT_DST (-100), NF_IP_PRI_FILTER (0), NF_IP_PRI_SECURITY (50), NF_IP_PRI_NAT_SRC (100), NF_IP_PRI_SELINUX_LAST (225), NF_IP_PRI_CONNTRACK_HELPER (300).

# policy -- default verdict if no match
accept, drop, queue, continue, return
```

## Firewall options to support
allowPing
allowedTCPPortRanges
allowedTCPPorts
allowedUDPPortRanges
allowedUDPPorts
checkReversePath
extraCommands?
logRefusedConnections
logRefusedPackets
logRefusedUnicastsOnly
logReversePathDrops
pingLimit
rejectPackets # icmp instead of drop
trustedInterfaces

## NAT interface
externalIP
externalInterface
forwardPorts
internalIPs
internalInterfaces


## Interface ideas
table family > table name > chain name
allow people to write both chain spec and rules free-form

