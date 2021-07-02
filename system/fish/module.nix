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
      # Including a nix-store version ensures that fish config is working OK
      # even on a freshly nixos-install'd system, while including the
      # out-of-store version *in front of* the store version allows dynamically
      # overriding it on a built system.
      shellInit = mkBefore (concatMapStringsSep "\n" (dir: ''
        set fish_function_path $fish_function_path[1] ${toString dir} ${dir} $fish_function_path[2..]
      '') cfg.functionDirs);
    };
  };
}
