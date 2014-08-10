{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.quassel.enable {
  services.quassel = {
    interface = "0.0.0.0";
    dataDir = "/srv/quassel/.config/quassel-irc.org";
  };
  networking.firewall.allowedTCPPorts = [ 4242 ];
}
