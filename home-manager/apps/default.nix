{ config, lib, pkgs, inputs, ... }:
let
  inherit (lib) optionals;
  pins = import ../../pins;
  inherit (pins) envy;
  # envy = /home/shados/technotheca/artifacts/media/software/nix/envy;
in
{
  programs.home-manager.enable = true;
  imports = [
    # Overwrite cataclysm with a version including various mods
    ./cataclysm
    ./chromium.nix
    ./mpv.nix
    # Custom neovim module
    (import "${envy}/home-manager.nix" { })
    # Config of it
    ./neovim
    # Explicitly merge in NixOS definitions as a baseline
    ../../nixos/apps/neovim
    ./openbox.nix
    ./tmux.nix
    ./urxvt.nix
  ];
  manual = {
    html.enable = true;
    json.enable = true;
    manpages.enable = true;
  };
  nixpkgs.overlays = [
    (self: super: {
      dmenu = super.dmenu.overrideAttrs (oldAttrs: {
        patchFlags = "-p2";
        patches = [
          ./dmenu/fuzzymatch.patch
        ];
      });

      pidgin-wrapped = super.pidgin.override {
        plugins = with super; [ pidgin-opensteamworks ];
      };
    })
  ];
  programs.git = {
    enable = true;
    userName = "Alexei Robyn";
    userEmail = "shados@shados.net";
    extraConfig = {
      push = {
        default = "simple";
      };
      pull = {
        ff = "only";
      };
      credential = {
        helper = if (config.sn.os != "darwin")
          then "cache"
          else "osxkeychain";
      };
      merge = {
        conflictstyle = "diff3";
        tool = "vimdiff";
      };
      diff = {
        tool = "vimdiff";
        colorMoved = "default";
      };
      color = {
        pager = "true";
        ui = "auto";
      };
      alias = {
        lgbase = "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --date=relative";
        lg  = "!git lgbase --graph --abbrev-commit --date-order";
        lgr = "!git lgbase -g";
      };
    };
  };
  sn.programs.nnn = {
    plugins = {
      o = pkgs.writeScript "open_selection" ''
        #!${pkgs.bash}/bin/bash
        selection=''${NNN_SEL:-''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.selection}

        if [ -s "$selection" ]; then
          read -rd $'\0' first_arg <"$selection"
          mime=$(${pkgs.xdg-utils}/bin/xdg-mime query filetype "$first_arg")
          opener=$(${pkgs.xdg-utils}/bin/xdg-mime query default "$mime")
          ${pkgs.findutils}/bin/xargs -0 gtk-launch "$opener" <"$selection" 2>/dev/null >/dev/null &
        else
          mime=$(${pkgs.xdg-utils}/bin/xdg-mime query filetype "$1")
          opener=$(${pkgs.xdg-utils}/bin/xdg-mime query default "$mime")
          ${pkgs.gtk3}/bin/gtk-launch "$opener" "$1" 2>/dev/null >/dev/null &
        fi
      '';
    };
  };
  sn.programs.pqiv = {
    settings = {
      fullscreen = true;
      hide-info-box = true;
      scale-images-up = true;
    };
    keyBindings = {
      q = "goto_file_relative(-1)";
      w = "goto_file_relative(1)";
    };
    actions = [
    ];
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.packages = with pkgs; [
    (writers.writePython3Bin "urldecode" { } ''
      import sys
      from urllib.parse import unquote
      if len(sys.argv) > 1:
          print(unquote(sys.argv[1]))
      else:
          print(unquote(sys.stdin.read()))
    '')
    (writers.writePython3Bin "urlencode" { } ''
      import sys
      from urllib.parse import quote
      if len(sys.argv) > 1:
          print(quote(sys.argv[1]))
      else:
          print(quote(sys.stdin.read()))
    '')
  ]
  # TODO More precise "graphical-only" check would be nice, so as to not
  # presume X11/xorg usage
  ++ optionals config.xsession.enable [
    libsecret
  ];
}
