{ config, pkgs, lib, ... }:

let
  quassel = pkgs.quasselDaemon_qt5;
  cfg = config.services.quassel;
in

{
  options = {
    services.quassel.debug = lib.mkOption {
      default = false;
      description = ''
        Whether or not to enable debug output.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    services.quassel = {
      interfaces = [ "0.0.0.0" ];
      dataDir = "/srv/quassel/.config/quassel-irc.org";
    };
    systemd.services.quassel = {
      requires = [ "postgresql.service" ];
      serviceConfig.Restart = "on-failure";
    };
    networking.firewall.allowedTCPPorts = [ 4242 ];

  };

}
