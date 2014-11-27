{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.quassel.enable {
  services.quassel = {
    interface = "0.0.0.0";
    dataDir = "/srv/quassel/.config/quassel-irc.org";
  };
  systemd.services.quassel.requires = [ "postgresql.service" ];
  networking.firewall.allowedTCPPorts = [ 4242 ];
}
