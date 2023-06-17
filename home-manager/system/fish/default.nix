{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    # Custom module
    ./module.nix
  ];
  config = mkIf (config.sn.os == "nixos") {
    home.packages = with pkgs; [
      fishPlugins.foreign-env
    ];

    programs.fish = {
      enable = true;

      # FIXME: Figure out how to get NIX_FISH_DIR in a non-static way, given
      # flake's purity shit
      shellInit = ''
        set HOSTNAME (hostname -s)
        # set -g NIX_FISH_DIR "${toString ./.}/"
        set -g NIX_FISH_DIR "/home/shados/.config/home-manager/system/fish"
        # Load Nix-managed system-wide, per-user, and local-system-specific Fish
        # config files
        for prefix in "" "$USER." "$HOSTNAME."
          for file_stem in env functions
            safe_source "$NIX_FISH_DIR/$prefix$file_stem"
          end
        end

        # Load sekrets (e.g. API keys) from local machine folder
        safe_source "$__fish_config_dir/secret.env"
      '';

      functionDirs = singleton ./functions;
    };
  };
}
