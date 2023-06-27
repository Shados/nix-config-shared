{ config, lib, pkgs, ... }:
with lib;
{
  config = mkMerge [
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = config.programs.zsh.enable;
        nix-direnv.enable = true;
        # ~/.config/direnv/config.toml, man direnv.toml(1)
        config = {
          bash_path = "${pkgs.bash}/bin/bash";
        };
        # ~/.config/direnv/direnvrc
        stdlib = ''
          source ${./layout_poetry.sh}
          # TODO cache these somehow? may not be worthwhile otherwise optimise
          # TODO remove unused aliases somehow? map for all of them at once?
          source ${./export_alias.sh}
          source ${./use-nix-shell.sh}
          declare -A direnv_layout_dirs
          : ''${XDG_CACHE_HOME:=$HOME/.cache}
          direnv_layout_dir() {
              echo "''${direnv_layout_dirs[$PWD]:=$(
                  echo -n "$XDG_CACHE_HOME"/direnv/layouts/
                  echo -n "$PWD" | shasum | cut -d ' ' -f 1
              )}"
          }
        '';
      };
    }
    { # Neovim integration TODO mkIf
      programs.fish.functions.v = ''
        # nvim wrapper function
        # Un/reloads direnv prior to starting nvim, if needed
        if command -s direnv > /dev/null
          direnv exec $PWD nvim $argv
        else
          nvim $argv
        end
      '';
      programs.zsh.shellAliases.v = "direnv exec $PWD nvim $argv";
    }
    { # Tmux integration TODO mkIf
      programs.fish.functions.tmux = ''
        # tmux wrapper function
        if set cmd (command -s tmux) > /dev/null
          if command -s direnv > /dev/null
            # Unloads direnv prior to starting tmux, if needed
            direnv exec / $cmd $argv
          else
            $cmd $argv
          end
        else
          $cmd $argv
        end
      '';
      programs.zsh.shellAliases.tmux = ''direnv exec / "${config.programs.tmux.package}/bin/tmux" $argv'';
    }
    (mkIf (config.sn.os == "nixos") { # Lorri integration
      services.lorri.enable = true;
      programs.direnv.stdlib = ''
        use_lorri() {
          eval "$(lorri direnv)"
        }
      '';
    })
    { # layout_python with custom venv directory
    programs.direnv.stdlib = ''
      source ${./layout_python_venv.sh}
    '';
    }
  ];
}
