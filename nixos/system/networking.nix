{ config, pkgs, lib, ... }:
let
  inherit (lib) mkDefault mkIf optionals;
in
{
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };
  networking.firewall.logRefusedConnections = false; # Too noisy
  # Saner than 'strict', if we're not acting as a router -- in particular
  # avoids some weird issues with portable devices being connected to the same
  # subnet on both wifi and ethernet.
  networking.firewall.checkReversePath = mkIf (!config.fragments.router.enable) "loose";
  networking.nameservers = mkDefault ([
    "9.9.9.9" "149.112.112.112" # Quad9
  ] ++ optionals config.networking.enableIPv6 [
    "2620:fe::fe" "2620:fe::9" # Quad9
  ]);
  users.users.shados.extraGroups = mkIf config.networking.networkmanager.enable [ "networkmanager" ];
}
