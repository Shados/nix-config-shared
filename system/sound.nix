{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments.sound;
in
{
  options = {
    fragments.sound = {
      enable = mkOption {
        type = types.bool;
        default = ! config.fragments.remote;
        description = ''
          Whether or not to enable sound.
        '';
      };
    };
  };

  config = mkIf (! cfg.enable) {
    sound = {
      enable = false;
      enableOSSEmulation = false;
    };
  };
}
