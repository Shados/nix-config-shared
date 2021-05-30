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
      # The functionDirs have to be prefixed to $fish_function_path so that they
      # can, e.g. override the default fish_prompt function.
      # Including a nix-store version ensures that fish config is working OK
      # even on a freshly nixos-install'd system, while including the
      # out-of-store version *in front of* the store version allows dynamically
      # overriding it on a built system.
      shellInit = mkBefore (concatMapStringsSep "\n" (dir: ''
        set -p fish_function_path ${dir}
        set -p fish_function_path ${toString dir}
      '') cfg.functionDirs);
    };
  };
}
