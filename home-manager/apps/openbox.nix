# TODO: Consider disabling xdg-autostart mechanism in favour of only using openbox's?
{ config, lib, pkgs, ... }:
with lib;
let
  inherit (config.lib.dag) entryBefore entryAfter entryAnywhere entryBetween;

  explorer = rec { pkg = pkgs.pcmanfm-qt; bin = "${pkg}/bin/pcmanfm-qt"; };
  runner = rec { pkg = pkgs.dmenu; bin = "${pkg}/bin/dmenu_run"; };
  terminal = rec { pkg = config.programs.urxvt.package; bin = "${pkg}/bin/urxvtc"; };
  music = rec { pkg = pkgs.mpc_cli; bin = "${pkg}/bin/mpc"; };
in
{
  lib.openbox = rec {
    launch = entryFn: name: data: nameValuePair name (
      entryFn (pkgs.writeScript "${name}.sh" (''
        #!${pkgs.bash}/bin/bash
      '' + data))
    );
    launchCli = launch (entryBefore [ "cli" ]);
    launchGraphics = launch (entryBetween [ "graphics" ] [ "cli" ]);
    launchTray = launch (entryBetween [ "tray" ] [ "graphics" ]);
    launchApp = launch (entryBetween [ "app" ] [ "tray" ]);
  };
  home.packages = with pkgs; mkIf config.xsession.windowManager.openbox.enable [
    explorer.pkg runner.pkg music.pkg

    xorg.xset xorg.xrdb nitrogen tint2 networkmanagerapplet pidgin-wrapped
    libnotify
  ];
  services.wired.enable = true;
  xsession.windowManager.openbox = {
    prependPaths = [
      "${config.home.homeDirectory}/technotheca/artifacts/packages/bin"
      "${config.home.homeDirectory}/technotheca/packages/bin"
    ];

    startupApps = with config.lib.openbox; listToAttrs [
      (launchCli "dpms" ''
        # Disable all DPMS timeouts, but ensure DPMS itself is enabled, so that
        # xlockmore can use it
        # NOTE: We also need a non-zero 'off' timer for this to work, sadly. So we set it to 5 hours.
        ${pkgs.xorg.xset}/bin/xset s 0 0 s noblank s noexpose dpms 0 0 ${toString (5 * 60 * 60)} +dpms &
      '')
      (launchTray "nitrogen" ''
        ${pkgs.nitrogen}/bin/nitrogen --restore &
      '')
      (launchTray "tint2" ''
        ${pkgs.tint2}/bin/tint2 &
      '')
      (launchApp "pidgin" ''
        ${pkgs.pidgin-wrapped}/bin/pidgin &
      '')
    ];

    placement.monitor = "active";
    theme = {
      name = "cathexis";
      fonts = {
        activeWindow = { name = "Pragmata Medium"; size = 9; weight = "normal"; };
        inactiveWindow = { name = "Pragmata Medium"; size = 9; weight = "bold"; };
        menuHeader = { name = "Pragmata Medium"; size = 9; weight = "normal"; };
        menuItem = { name = "Pragmata Medium"; size = 9; weight = "normal"; };
        activeOnScreenDisplay = { name = "Pragmata Medium"; size = 9; };
        inactiveOnScreenDisplay = { name = "Pragmata Medium"; size = 9; };
      };
    };

    applications = [
      # Strip window titlebars from all windows
      { class = "*";
        decor = false;
      }
      { class = "dzen"; name = "dzen2";
        layer = "below";
      }
    ];

    keyboard.keybind = {
      # Desktop management binds
      "W-1 W-A-F1" = singleton { action = "desktop"; desktop = 1; };
      "W-2 W-A-F2" = singleton { action = "desktop"; desktop = 2; };
      "W-3 W-A-F3" = singleton { action = "desktop"; desktop = 3; };
      "W-4 W-A-F4" = singleton { action = "desktop"; desktop = 4; };
      "W-Tab" = singleton { action = "goToDesktop"; to = "next"; wrap = true; };
      "W-A-d" = singleton "toggleShowDesktop";

      # Window management binds
      "A-F4" = singleton "close";
      "A-Escape" = [
        "lower"
        "focusToBottom"
        "unfocus"
      ];
      "A-Space" = singleton { action = "showMenu"; menu = "client-menu"; };
      # Window switching
      "A-Tab" = singleton "nextWindow";
      "A-S-Tab" = singleton "previousWindow";
      "C-A-Tab" = singleton { action = "nextWindow"; panels = true; desktop = true; };
      # Window side-snapping
      "W-h" = [
        { action = "unmaximize"; direction = "both"; }
        { action = "maximize"; direction = "vertical"; }
        { action = "moveResizeTo"; width = "50%"; }
        { action = "moveToEdge"; direction = "west"; }
      ];
      "W-l" = [
        { action = "unmaximize"; direction = "both"; }
        { action = "maximize"; direction = "vertical"; }
        { action = "moveResizeTo"; width = "50%"; }
        { action = "moveToEdge"; direction = "east"; }
      ];
      "W-j" = singleton "unmaximize";
      "W-k" = singleton "maximize";

      # Application-launching bindings
      "W-A-e" = singleton { action = "execute"; command = explorer.bin; };
      "C-A-e" = singleton { action = "execute"; command = "${terminal.bin} -e nvim"; };
      "W-A-r" = singleton { action = "execute"; command = runner.bin; };
      "W-A-t" = singleton { action = "execute"; command = terminal.bin; };
      # # MPD binds
      # "W-A-c" = singleton { action = "execute"; command = "${music.bin} toggle"; };
      # "W-A-f" = singleton { action = "execute"; command = "${music.bin} volume +5"; };
      # "W-A-g" = singleton { action = "execute"; command = "${music.bin} volume -5"; };
      # "W-A-v" = singleton { action = "execute"; command = "${music.bin} prev"; };
      # "W-A-b" = singleton { action = "execute"; command = "${music.bin} next"; };
    };
    mouse.mousebind = {
      "frame" = [
        { button = "A-Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
        { button = "A-Left"; action = "click"; actions = singleton "unshade"; }
        { button = "A-Left"; action = "drag"; actions = singleton "move"; }
        { button = "A-Right"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
        { button = "A-Right"; action = "drag"; actions = singleton "resize"; }
      ];
      "titlebar" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
        { button = "Left"; action = "drag"; actions = singleton "move"; }
        { button = "Left"; action = "doubleClick"; actions = singleton {
            action = "toggleMaximize";
            direction = "both";
          };
        }
        { button = "Middle"; action = "press"; actions = [
            "lower"
            "focusToBottom"
            "unfocus"
          ];
        }
        { button = "Up"; action = "click"; actions = [
            "shade"
            "focusToBottom"
            "unfocus"
            "lower"
          ];
        }
        { button = "Down"; action = "click"; actions = [
            "unshade"
            "raise"
          ];
        }
        { button = "Right"; action = "press"; actions = [
            "focus"
            "raise"
            { action = "showMenu"; menu = "client-menu"; }
          ];
        }
      ];
      "top bottom left right" = [
        { button = "Right"; action = "press"; actions = [
            "focus"
            "raise"
            { action = "showMenu"; menu = "client-menu"; }
          ];
        }
      ];
      "bottom left right" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
      ];
      "top" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
        { button = "Left"; action = "drag"; actions = singleton {
            action = "resize"; edge = "top";
          };
        }
      ];
      "left" = [
        { button = "Left"; action = "drag"; actions = singleton {
            action = "resize"; edge = "left";
          };
        }
      ];
      "right" = [
        { button = "Left"; action = "drag"; actions = singleton {
            action = "resize"; edge = "right";
          };
        }
      ];
      "bottom" = [
        { button = "Left"; action = "drag"; actions = singleton {
            action = "resize"; edge = "bottom";
          };
        }
      ];
      "tLCorner tRCorner bLCorner bRCorner" = [
        { button = "Left"; action = "drag"; actions = singleton "resize"; }
      ];
      "tLCorner tRCorner" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
      ];
      "bLCorner bRCorner" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
      ];
      "client" = [
        { button = "Left Middle Right"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
      ];
      "icon" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
            { action = "showMenu"; menu = "client-menu"; }
          ];
        }
        { button = "Right"; action = "press"; actions = [
            "focus"
            "raise"
            { action = "showMenu"; menu = "client-menu"; }
          ];
        }
      ];
      "allDesktops" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
        { button = "Left"; action = "click"; actions = singleton "toggleOmnipresent"; }
      ];
      "shade" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
        { button = "Left"; action = "click"; actions = singleton "toggleShade"; }
      ];
      "iconify" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
        { button = "Left"; action = "click"; actions = singleton "iconify"; }
      ];
      "maximize" = [
        { button = "Left Middle Right"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
        { button = "Left"; action = "click"; actions = singleton {
            action = "toggleMaximize"; direction = "both";
          };
        }
        { button = "Middle"; action = "click"; actions = singleton {
            action = "toggleMaximize"; direction = "vertical";
          };
        }
        { button = "Right"; action = "click"; actions = singleton {
            action = "toggleMaximize"; direction = "horizontal";
          };
        }
      ];
      "close" = [
        { button = "Left"; action = "press"; actions = [
            "focus"
            "raise"
            "unshade"
          ];
        }
        { button = "Left"; action = "click"; actions = singleton "close"; }
      ];
      "desktop" = [
        { button = "Left Right"; action = "press"; actions = [
            "focus"
            "raise"
          ];
        }
        { button = "Up"; action = "click"; actions = singleton {
            action = "goToDesktop"; to = "previous"; wrap = true;
          };
        }
        { button = "Down"; action = "click"; actions = singleton {
            action = "goToDesktop"; to = "next"; wrap = true;
          };
        }
      ];
      "root" = [
        { button = "Middle"; action = "press"; actions = singleton {
            action = "showMenu"; menu = "client-list-combined-menu";
          };
        }
        { button = "Right"; action = "press"; actions = singleton {
            action = "showMenu"; menu = "root-menu";
          };
        }
      ];
    };
  };
}
