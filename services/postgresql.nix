{ config, pkgs, lib, ... }:

lib.mkIf config.services.postgresql.enable {
  services.postgresql = {
    package = pkgs.postgresql;
    dataDir = "/srv/postgresql94";
  };
  systemd.services.postgresql = {
    serviceConfig.Restart = "on-failure";
  };
}
