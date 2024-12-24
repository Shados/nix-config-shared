{ config, lib, pkgs, ... }:
let
  inherit (lib) getExe mkDefault mkIf mkMerge mkOption;
  cfg = config.services.xsecurelock;
in
{
  options.services.xsecurelock = {
    enable = mkOption {
      default = config.services.screen-locker.enable;
      defaultText = "config.services.screen-locker.enable";
      example = true;
      description = "Whether to enable the xsecurelock screen locker.";
      type = lib.types.bool;
    };
  };
  config = mkIf cfg.enable (let
    locker = pkgs.writers.writeBash "xsecurelock-shados" ''
      export XSECURELOCK_AUTH_TIMEOUT=30
      export XSECURELOCK_BLANK_TIMEOUT=5
      exec -a "$0" ${pkgs.xsecurelock}/bin/xsecurelock "$@"
    '';
  in {
    services.screen-locker.lockCmd = "${getExe config.lib.xss-locker-wrapper} ${locker}";
    services.screen-locker.xss-lock.extraOptions = mkDefault [
      "-n ${pkgs.xsecurelock}/libexec/xsecurelock/dimmer -l"
    ];
    home.packages = with pkgs; [
      xsecurelock
    ];
  });
}
