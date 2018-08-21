{ config, pkgs, ... }:

{
  services.xserver.displayManager = {
    slim = {
      theme = ./shadosnet-nixos-slim-theme.tar.gz;
    };
  };
  environment.sessionVariables = {
    SLIM_CFGFILE = toString (pkgs.writeText "slim_with_lock.conf" (
      (builtins.readFile config.services.xserver.displayManager.job.environment.SLIM_CFGFILE)
      + ''
        dpms_standby_timeout 0
        dpms_off_timeout 0
        bell 0
      ''
    ));
    SLIM_THEMESDIR = toString config.services.xserver.displayManager.job.environment.SLIM_THEMESDIR;
  };
}
