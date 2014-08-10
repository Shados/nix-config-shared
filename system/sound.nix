{ config, pkgs, ... }:

with pkgs.lib;
let
  cfg = config.fragments.sound;
in
{
  options = {
    fragments.sound = {
      enable = mkOption {
        type = types.bool;
        default = false;
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
