{ config, pkgs, lib, ... }:

let 
  cfg = config.fragments.router;
in
with lib;
{
  config = mkMerge [
    (mkIf (cfg.enable) {
      # NAT setup
      networking.nat = {
        # enable = true;
        externalInterface = cfg.extInt;
        internalIPs = [ "${cfg.intSubnet + ".0/24"}" ];
      };
      # Tuning kernel networking queues/buffers for heavier usage and connection counts
      boot.kernel.sysctl = {
        "net.ipv4.neigh.default.gc_thresh1" = 1024;
        "net.ipv4.neigh.default.gc_thresh2" = 2048;
        "net.ipv4.neigh.default.gc_thresh3" = 4096;
        "net.core.wmem_max" = 12582912;
        "net.core.rmem_max" = 12582912;
        "net.core.optmem_max" = 12582912;
        "net.ipv4.tcp_wmem" = "10240 87380 12582912";
        "net.ipv4.tcp_rmem" = "10240 87380 12582912";
        "net.ipv4.tcp_mem" = "10240 87380 12582912";
        "net.core.netdev_max_backlog" = 5000;

        # Bufferbloat
        "net.ipv4.tcp_ecn" = 1;
        "net.ipv4.tcp_sack" = 1;
        "net.ipv4.tcp_dsack" = 1;
      };
    })
    (mkIf (cfg.enable && cfg.enableBridge) {
      networking = {
        bridges.${cfg.intBridge}.interfaces = cfg.intInts;
        interfaces.${cfg.intBridge} = {
          ipAddress = cfg.intSubnet + ".1";
          prefixLength = 24;
        };
      };
    })
  ];
}
