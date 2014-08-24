{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.teamspeak3.enable {
  networking.firewall = {
    allowedTCPPorts = [ 54203 ];
    allowedUDPPorts = [ 54203 ];
  };
  services.teamspeak3 = {
    dataDir = "/srv/teamspeak3-server";
  };
}
