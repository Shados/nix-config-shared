{ config, lib, pkgs, ... }:
let
  inherit (lib) escapeShellArg getExe mkEnableOption mkIf mkMerge mkOption singleton types;
  dCfg = config.programs.discord;
  vCfg = config.programs.vesktop;
in
{
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
  config = let
    # TODO figure out DST/timezone issue
    mkDiscordSandbox = pkg: pkgs.bwrapper {
      inherit pkg;
      runScript = pkg.pname;
      overwriteExec = true;
      additionalFolderPathsReadWrite = [
          "$XDG_CONFIG_HOME/${pkg.pname}" # Configuration/session/etc. storage
      ];
      # additionalFolderPaths = [
      # ];
      dbusOwns = [
        "com.discordapp.Discord"
      ];
      appendBwrapArgs = [
        "--ro-bind $XAUTHORITY $XAUTHORITY"
        "--setenv GTK_USE_PORTAL 1"
        "--setenv GDK_DEBUG portals"
      ];
      dbusLogging = false;
      # dbusTalks = [
      # ];
    };
  in mkMerge [
    {
      nixpkgs.overlays = singleton (final: prev: {
        sandboxedDiscord = mkDiscordSandbox pkgs.discord;
        sandboxedVesktop = mkDiscordSandbox pkgs.vesktop;
      });
    }
    (mkIf dCfg.enable {
      home.packages = singleton pkgs.sandboxedDiscord;
      xsession.windowManager.openbox.startupApps = with config.lib.openbox; mkIf dCfg.startOnLogin (builtins.listToAttrs [
        (launchApp "discord" ''
          ${pkgs.sandboxedDiscord}/bin/discord &
        '')
      ]);
    })
    (mkIf vCfg.enable {
      home.packages = singleton pkgs.sandboxedVesktop;
      xsession.windowManager.openbox.startupApps = with config.lib.openbox; mkIf dCfg.startOnLogin (builtins.listToAttrs [
        (launchApp "vesktop" ''
          ${pkgs.sandboxedVesktop}/bin/vesktop &
        '')
      ]);
    })

    # Custom toggle-mute keybind, seeing as discord can't manage to do either cusotm keybinds or global keybinds itself
    (mkIf (dCfg.enable || vCfg.enable) {
      xsession.windowManager.openbox.mouse.mousebind = let
        toggleVesktopMute = {
          # NOTE: I found which mouse Button# was correct using xev
          button = "C-Button9"; action = "press"; actions = [
            { action = "execute";
              command = "${getExe pkgs.bash} -c ${escapeShellArg shellCmd}";
            }
          ];
        };
        shellCmd = "${xdotool} search --classname '^(discord|vesktop)$' windowfocus --sync %1 key --delay 1 'ctrl+shift+m' windowfocus \"$(${xdotool} getwindowfocus)\"";
        xdotool = getExe pkgs.xdotool;
      in {
        "frame" = singleton toggleVesktopMute;
        "desktop" = singleton toggleVesktopMute;
      };
    })
  ];
}
