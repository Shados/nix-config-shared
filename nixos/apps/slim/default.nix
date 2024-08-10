{ config, lib, pkgs, ... }:

let
  x_env = config.services.displayManager.job.environment;
  inherit (builtins) hasAttr getAttr;
in

{
  services.displayManager = {
    slim = {
      theme = ./shadosnet-nixos-slim-theme.tar.gz;
    };
  };
  environment.sessionVariables = {
    SLIM_CFGFILE = lib.mkIf (hasAttr "SLIM_CFGFILE" x_env) (toString (pkgs.writeText "slim_with_lock.conf" (
      (builtins.readFile (getAttr "SLIM_CFGFILE" x_env))
      + ''
        dpms_standby_timeout 0
        dpms_off_timeout 0
        bell 0
      ''
    )));
    SLIM_THEMESDIR = lib.mkIf (hasAttr "SLIM_THEMESDIR" x_env) (toString (getAttr "SLIM_THEMESDIR" x_env));
  };
}
