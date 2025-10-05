{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.services.teamspeak3.enable {
  networking.firewall = {
    allowedUDPPorts = [ 54203 ];
    allowedTCPPorts = [
      10011
      30033
    ];
  };
  services.teamspeak3 = {
    dataDir = "/srv/teamspeak3-server";
  };
}
