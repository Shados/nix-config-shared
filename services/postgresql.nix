{ config, lib, pkgs, ... }:

lib.mkIf config.services.postgresql.enable {
  services.postgresql = {
    package = lib.mkDefault pkgs.postgresql94; # TODO: migrate my shit to a more recent postgres and update the default here
    dataDir = lib.mkDefault "/srv/postgresql94";
  };
  systemd.services.postgresql = {
    serviceConfig.Restart = "on-failure";
  };
}
