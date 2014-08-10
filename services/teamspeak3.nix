{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.teamspeak3.enable {
  networking.firewall.allowedTCPPorts = [ 54203 ];
}
