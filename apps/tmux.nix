{ config, lib, pkgs, ... }:
with lib;
{
  systemd.user.services.tmux = {
    enable = true;
    description = "Terminal Multiplexer daemon";
    documentation = [ "man:tmux(1)" ];
    reloadIfChanged = true;
    # TODO hack on tmux to make it re-execute itself to do upgrades of the tmux
    # server? Would be pretty cool
    reload = /*ft=sh*/''
      ${pkgs.tmux}/bin/tmux source-file /etc/tmux.conf
    '';
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.tmux}/bin/tmux start-server";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
      Restart = "on-abnormal";
    };
    wantedBy = [ "default.target" ];
    restartTriggers = [ config.environment.etc."tmux.conf".source ];
    # Points to /run/user/$(id -u) by default
    environment.TMUX_TMPDIR = mkIf config.programs.tmux.secureSocket "%t/";
  };

  # TODO custom structured tmux config? nixpkgs one is derp AF
  programs.tmux = {
    enable = true;
    secureSocket = true;
    clock24 = true;
    keyMode = "vi";
    shortcut = "a";
    terminal = "screen-256color";
    extraTmuxConf = ''
      # Prevent the server from quitting when there are no live sessions
      set-option -s exit-empty off

      bind-key C-o rotate-window -D

      # Window title modification stuff
        set -g set-titles on
        # Set window title string
        #  #H  Hostname of local host
        #  #I  Current window index
        #  #P  Current pane index
        #  #S  Session name
        #  #T  Current window title
        #  #W  Current window name
        #  #   A literal ‘#’
        set -g set-titles-string '#h:#S:#W@#I'

        # Automatically set window title
        setw -g automatic-rename

      # Makes new panes/windows start in the same directory as the current pane
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Vim-style pane navigation bindings {{{
      unbind k
      unbind j
      unbind h
      unbind l

      bind k select-pane -U
      bind j select-pane -D
      bind h select-pane -L
      bind l select-pane -R
      # }}}

      # Vim-style pane resize bindings {{{
      unbind M-Up
      unbind M-Down
      unbind M-Left
      unbind M-Right
      unbind M-k
      unbind M-j
      unbind M-h
      unbind M-l

      unbind C-Up
      unbind C-Down
      unbind C-Left
      unbind C-Right
      unbind C-k
      unbind C-j
      unbind C-h
      unbind C-l

      bind -r M-k resize-pane -U 5
      bind -r M-j resize-pane -D 5
      bind -r M-h resize-pane -L 5
      bind -r M-l resize-pane -R 5

      bind -r C-k resize-pane -U
      bind -r C-j resize-pane -D
      bind -r C-h resize-pane -L
      bind -r C-l resize-pane -R
      # }}}

      ##CLIPBOARD selection integration
      ##Requires prefix key before the command key
      #Copy tmux paste buffer to CLIPBOARD
      #bind -t vi-copy y copy-pipe 'xclip -in -selection clipboard'
      #Copy CLIPBOARD to tmux paste buffer and paste tmux paste buffer
      #bind C-v run "tmux set-buffer -- \"$(xclip -o -selection clipboard)\"; tmux paste-buffer"
      # TODO make clipboard shit actually work

      # Integrate urxvt middle-click copy/paste with tmux
      set-option -ga terminal-overrides ',rxvt-uni*:XT:Ms=\E]52;%p1%s;%p2%s\007'

      # Support for 24-bit colors when using rxvt-unicode (need patched version)
      # set-option -ga terminal-overrides ",rxvt-unicode-256color:Tc"
      set-option -ga terminal-overrides ",*:Tc"

      # basic settings
      set -g mouse on

      # status bar
      set-option -g status-justify right
      set-option -g status-interval 5
      set-option -g status-left-length 30
      set-option -g visual-activity on
      set-window-option -g monitor-activity on
      set-window-option -g window-status-current-style fg=black

      # clock
      set-window-option -g clock-mode-style 24

      # Layout stuff
      set-window-option -g main-pane-width 120

      # Color scheme {{{
        # default statusbar colors
        set -g status-style bg=yellow,fg=black,none

        # default window title colors
        setw -g window-status-style bg=default,fg=default

        # active window title colors 
        setw -g window-status-current-style bg=default,fg=brightblack,dim

        # pane border 
        set -g pane-border-style bg=default,fg=magenta
        set -g pane-active-border-style bg=default,fg=yellow

        # command line/message text
        set -g message-style bg=black,fg=yellow

        # pane number display
        set -g display-panes-active-colour yellow
        set -g display-panes-colour brightblue

        # clock
        setw -g clock-mode-colour yellow
      # }}}

      # Fixes
        # Fix scrolling and shit
        #set -g terminal-overrides 'xterm*:smcup@:rmcup@'
        # Fix Ctrl+Left/Right
        set-window-option  -g xterm-keys on
        # Fix neovim Esc->letter key producing stuff like 'á' and 'æ'
        set -s escape-time 0

        # Fix Putty ctrl-arrow keys as per tmux manual
        set -ga terminal-overrides ",xterm*:kLFT5=\eOD:kRIT5=\eOC:kUP5=\eOA:kDN5=\eOB:smkx@:rmkx@"

      # Direnv support
      set-option -g update-environment "DIRENV_DIFF DIRENV_DIR DIRENV_WATCHES"
      set-environment -gu DIRENV_DIFF
      set-environment -gu DIRENV_DIR
      set-environment -gu DIRENV_WATCHES
      set-environment -gu DIRENV_LAYOUT
    '';
  };
}
