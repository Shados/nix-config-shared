{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.postgresql.enable {
  services.postgresql = {
    package = pkgs.postgresql92;
    dataDir = "/srv/postgresql";
  };
}
