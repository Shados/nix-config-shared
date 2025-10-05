{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkIf
    mkOption
    singleton
    types
    ;
  cfg = config.programs.chromium;
in
{
  options.programs.chromium = {
    flags = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        A list of command-line flags to configure chromium to use, via
        chromium-launcher.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = singleton pkgs.nur.repos.shados.chromium-launcher;
    xdg.configFile."chromium-flags.conf".text = concatStringsSep "\n" cfg.flags + "\n";
  };
}
