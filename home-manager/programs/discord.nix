{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    singleton
    types
    ;
  dCfg = config.programs.discord;
  vCfg = config.programs.vesktop;
in
{
  disabledModules = [
    "programs/discord.nix"
    "programs/vesktop.nix"
  ];
  options.programs.discord = {
    enable = mkEnableOption "discord chat";
    sandbox = mkOption {
      type = with types; bool;
      default = true;
      description = ''
        Whether or not to sandbox discord using bubblewrap.
      '';
    };
    startOnLogin = mkOption {
      type = with types; bool;
      default = false;
      description = ''
        Whether or not to automatically start discord on graphical login.
      '';
    };
  };
  options.programs.vesktop = {
    enable = mkEnableOption "vesktop chat";
    sandbox = mkOption {
      type = with types; bool;
      default = true;
      description = ''
        Whether or not to sandbox vesktop using bubblewrap.
      '';
    };
    startOnLogin = mkOption {
      type = with types; bool;
      default = false;
      description = ''
        Whether or not to automatically start vesktop on graphical login.
      '';
    };
  };
  config =
    let
      # TODO figure out DST/timezone issue
      # FIXME: make it cd to home before starting discord
      mkDiscordSandbox =
        pkg:
        pkgs.mkBwrapper {
          app = {
            package = pkg;
            runScript = pkg.pname;
            env = {
              XAUTHORITY = "$XAUTHORITY";
              GTK_USE_PORTAL = 1;
              # GDK_DEBUG = "portals";
              GDK_SYNCHRONIZE = "true"; # FIXME: Figure out why it crashes on start without this
            };
            overwriteExec = true;
          };
          mounts = {
            # FIXME: Not sure why this is needed, but without it XAUTHORITY fails
            # to work, despite its path being explicitly ro-bound already
            privateTmp = false;
            readWrite = [
              "$XDG_CONFIG_HOME/${pkg.pname}" # Configuration/session/etc. storage
            ];
          };
          dbus.session.owns = [
            "com.discordapp.Discord"
          ];
          dbus.logging = false;
          sockets.wayland = false;
        };
    in
    mkMerge [
      {
        nixpkgs.overlays = singleton (
          final: prev: {
            sandboxedDiscord = mkDiscordSandbox pkgs.discord;
            sandboxedVesktop = mkDiscordSandbox pkgs.vesktop;
          }
        );
      }
      (mkIf dCfg.enable {
        home.packages = singleton pkgs.sandboxedDiscord;
        xsession.windowManager.openbox.startupApps =
          with config.lib.openbox;
          mkIf dCfg.startOnLogin (
            builtins.listToAttrs [
              (launchApp "discord" ''
                ${pkgs.sandboxedDiscord}/bin/discord &
              '')
            ]
          );
      })
      (mkIf vCfg.enable {
        home.packages = singleton pkgs.sandboxedVesktop;
        xsession.windowManager.openbox.startupApps =
          with config.lib.openbox;
          mkIf dCfg.startOnLogin (
            builtins.listToAttrs [
              (launchApp "vesktop" ''
                ${pkgs.sandboxedVesktop}/bin/vesktop &
              '')
            ]
          );
      })

      # Custom toggle-mute keybind, seeing as discord can't manage to do either cusotm keybinds or global keybinds itself
      (mkIf (dCfg.enable || vCfg.enable) {
        #xsession.windowManager.openbox.mouse.mousebind =
        #  let
        #    toggleVesktopMute = {
        #      # NOTE: I found which mouse Button# was correct using xev
        #      button = "C-Button9";
        #      action = "press";
        #      actions = [
        #        {
        #          action = "execute";
        #          command = "${pkgs.writeScript "discord-toggle-mute" ''
        #            #!${pkgs.stdenv.shell}
        #            orig_winid=$(${xdotool} getwindowfocus)
        #            ${xdotool} search --classname '^(discord|vesktop)$' | while read -r winid; do
        #              ${xdotool} windowfocus --sync "$winid"
        #              ${xdotool} key --delay 1 'ctrl+shift+m'
        #            done
        #            ${xdotool} windowfocus --sync "$orig_winid"
        #          ''}";
        #        }
        #      ];
        #    };
        #    xdotool = getExe pkgs.xdotool;
        #  in
        #  {
        #    "frame" = singleton toggleVesktopMute;
        #    "desktop" = singleton toggleVesktopMute;
        #  };
      })
    ];
}
