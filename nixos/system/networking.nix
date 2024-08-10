{ config, pkgs, lib, ... }:
{
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };
  networking.firewall.logRefusedConnections = false; # Too noisy
}
