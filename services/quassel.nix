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
      interface = "0.0.0.0";
      dataDir = "/srv/quassel/.config/quassel-irc.org";
    };
    systemd.services.quassel = {
      requires = [ "postgresql.service" ];
      serviceConfig.Restart = "on-failure";
      serviceConfig.ExecStart = lib.mkForce "${quassel}/bin/quasselcore --listen=${cfg.interface} --port=${toString cfg.portNumber} --configdir=${cfg.dataDir} ${lib.optionalString cfg.debug "-d"}";
    };
    networking.firewall.allowedTCPPorts = [ 4242 ];

  };

}
