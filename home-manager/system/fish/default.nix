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

      shellInit = ''
        set -g NIX_FISH_DIR "${toString ./.}"
        for config_dir in "$NIX_FISH_DIR" "$__fish_config_dir"
          for prefix in "" "$USER." "$hostname."
            for file_stem in env functions
              safe_source "$config_dir/$prefix$file_stem.fish"
            end
          end
        end

        # Load sekrets (e.g. API keys) from local machine folder
        safe_source "$__fish_config_dir/secret.env"
      '';

      functionDirs = singleton ./functions;
    };
  };
}
