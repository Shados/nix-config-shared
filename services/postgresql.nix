{ config, pkgs, lib, ... }:

lib.mkIf config.services.postgresql.enable {
  services.postgresql = {
    package = pkgs.postgresql94; # TODO: migrate my shit to a more recent postgres and update the default here
    dataDir = "/srv/postgresql94";
  };
  systemd.services.postgresql = {
    serviceConfig.Restart = "on-failure";
  };
}
