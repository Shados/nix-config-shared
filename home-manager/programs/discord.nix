{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkForce
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
    "programs/vesktop"
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
      mkDiscordSandbox =
        pkg:
        (mkNixPak {
          config = { config, sloth, ... }: {
            imports = [
              inputs.nixpak.nixpakModules.gui-base
              inputs.nixpak.nixpakModules.network
            ];
            app.package = pkg;
            flatpak.appId = "com.discordapp.Discord";
            gpu.provider = mkForce "nixos";
            bubblewrap.bind.rw = [
              (sloth.concat' sloth.xdgConfigHome "/${pkg.pname}")
              (sloth.concat' sloth.xdgConfigHome "/mimeapps.list")
            ];
            bubblewrap.env.PATH = lib.makeBinPath (with pkgs; [ xdg-utils ]);
            bubblewrap.bindEntireStore = false;
            bubblewrap.extraStorePaths = with pkgs; [
              xdg-utils # xdg-open
              config.locale.package
              mesa
            ];
            bubblewrap.sockets.pulse = true;
            bubblewrap.sockets.pipewire = true;
            bubblewrap.sockets.x11 = true;
            bubblewrap.sockets.wayland = mkForce false;
            dbus.enable = true;
            dbus.policies = {
              "org.freedesktop.Notifications" = "talk";
              "org.freedesktop.ScreenSaver" = "talk";
              "com.canonical.AppMenu.Registrar" = "talk";
              "com.canonical.Unity.LauncherEntry" = "talk";
              "com.canonical.indicator.application" = "talk";
              "org.kde.StatusNotifierWatcher" = "talk";
            };
            dbus.rules.call = {
              "org.freedesktop.portal.*" = singleton "*@/org/freedesktop/portal/desktop";
            };
            dbus.rules.broadcast = {
              "org.freedesktop.portal.Desktop" = singleton "*@/org/freedesktop/portal/desktop";
            };

            timeZone.enable = true;
            timeZone.provider = "host";
          };
        }).config.env;

      mkNixPak = inputs.nixpak.lib.nixpak { inherit lib pkgs; };
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
