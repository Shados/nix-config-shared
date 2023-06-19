{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.fish;
in
{
  options = {
    programs.fish = {
      functionDirs = mkOption {
        type = with types; listOf (either path str);
        default = [];
        description = ''
          A list of paths to add to the fish function path, from which
          functions will be autoloaded.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    programs.fish = {
      # The functionDirs have to be added early in $fish_function_path so that
      # they can, e.g. override the default fish_prompt function. We add them
      # behind the first item because the first item refers to the user's XDG
      # config dir for fish.
      shellInit = mkBefore (concatMapStringsSep "\n" (dir: ''
        set fish_function_path $fish_function_path[1] ${dir} $fish_function_path[2..]
      '') cfg.functionDirs);
    };
  };
}
