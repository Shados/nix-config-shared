{ config, pkgs, lib, ... }:
let
  inherit (lib) mkDefault optionals;
in
{
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };
  networking.firewall.logRefusedConnections = false; # Too noisy
  networking.nameservers = mkDefault ([
    "9.9.9.9" "149.112.112.112" # Quad9
  ] ++ optionals config.networking.enableIPv6 [
    "2620:fe::fe" "2620:fe::9" # Quad9
  ]);
}
