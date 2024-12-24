{ config, pkgs, lib, ... }:
let
  inherit (lib) mkDefault mkIf mkMerge optionals;
in
{
  config = mkMerge [
    {
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq_codel";
      };
      networking.firewall.logRefusedConnections = mkDefault false; # Too noisy
      # Saner than 'strict', if we're not acting as a router -- in particular
      # avoids some weird issues with portable devices being connected to the same
      # subnet on both wifi and ethernet.
      networking.firewall.checkReversePath = mkIf (!config.fragments.router.enable) "loose";
      networking.nameservers = mkDefault ([
        "9.9.9.9" "149.112.112.112" # Quad9
      ] ++ optionals config.networking.enableIPv6 [
        "2620:fe::fe" "2620:fe::9" # Quad9
      ]);
    }
    (mkIf config.networking.networkmanager.enable {
      networking.networkmanager = {
        # Use stable random-seeded MAC addresses, with per-SSID seeding for the
        # wifi MAC addresses. Offers good blend of privacy and functionality.
        ethernet.macAddress = mkDefault "stable";
        wifi.macAddress = mkDefault "stable-ssid";

        # Bump up the log level from warn
        logLevel = mkDefault "INFO";

        # Enable WoL by default
        connectionConfig."ethernet.wake-on-lan" = mkDefault "magic";

        # Don't try to set the hostname
        settings.main.hostname-mode = mkDefault "none";
      };
    })
  ];
}
