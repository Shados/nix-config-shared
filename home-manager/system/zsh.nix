{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.zsh.enable {
    programs.zsh = {
      autosuggestion.enable = true;
      autocd = true;
      defaultKeymap = "viins";
      # defaultKeymap?
      oh-my-zsh = {
        enable = true;
        plugins = [
          "vi-mode"
          "git"
          "sudo"
          "brew"
        ];
        custom = toString (
          pkgs.runCommand "oh-my-zsh-custom" { } ''
            mkdir -p "$out/themes"
            cp -r ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k "$out/themes/powerlevel10k"
          ''
        );
        theme = "powerlevel10k/powerlevel10k";
      };
      history = rec {
        share = false;
        extended = true;
        save = 1000000000;
        size = save;
      };
      initContent = ''
        # TODO check for interactive session
        # if ! [[ -v TMUX ]]; then
        #   tmux
        # fi
        source "$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
        # Write out history line-by-line, rather than on shell session exit
        setopt INC_APPEND_HISTORY
      '';
      # Ensure bash completions are also used
      completionInit = ''
        autoload -U compinit && compinit
        autoload bashcompinit && bashcompinit
      '';
    };
  };
}
