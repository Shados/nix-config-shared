{
  nixpkgs ? import <nixpkgs> { },
}:
with nixpkgs;

runCommand "build-openbox-config"
  {
    preferLocalBuild = true;
    allowSubstitutes = false;
    nativeBuildInputs = [
      libxslt
    ];
    config = builtins.toFile "nix-config.xml" (
      builtins.toXML {
        resistance = {
          strength = 10;
          screenEdgeStrength = 20;
        };
        focus = {
          focusNew = true;
          followMouse = false;
          focusLast = true;
          underMouse = false;
          focusDelay = 200;
          raiseOnFocus = false;
        };
        margins = {
          top = 0;
          bottom = 0;
          left = 0;
          right = 0;
        };
        menu = {
          file = "menu.xml"; # TODO custom menu module too?
          hideDelay = 200;
          middle = false;
          submenuShowDelay = 100;
          submenuHideDelay = 400;
          applicationIcons = true;
          manageDesktops = true;
        };
        dock = {
          position = "TopLeft";
          floatingX = 0;
          floatingY = 0;
          noStrut = false;
          stacking = "Above";
          direction = "Vertical";
          autoHide = false;
          hideDelay = 300;
          showDelay = 300;
          moveButton = "Middle";
        };
        keyboard = {
          rebindOnMappingNotify = true;
          chainQuitKey = "C-g";
          keybind = {
            "W-A-F1" = [
              {
                action = "Desktop";
                desktop = 1;
              }
            ];
            "W-A-F2" = [
              {
                action = "Desktop";
                desktop = 2;
              }
            ];
            "A-F4" = [
              {
                action = "Close";
              }
            ];
            "A-space" = [
              {
                action = "ShowMenu";
                menu = "client-menu";
              }
            ];
            "W-A-t" = [
              {
                action = "Execute";
                command = "urxvtc";
                startupnotify = {
                  enabled = true;
                  name = "URxvt client";
                };
              }
            ];
          };
        };
        mouse = {
          dragThreshold = 8;
          doubleClickTime = 200;
          screenEdgeWarpTime = 400;
          mousebind = {
            "Frame" = [
              {
                button = "A-Left";
                action = "press";
                actions = [
                  { action = "Focus"; }
                  { action = "Raise"; }
                ];
              }
            ];
            "Titlebar" = [
              {
                button = "Left";
                action = "press";
                actions = [
                  { action = "Focus"; }
                  { action = "Raise"; }
                ];
              }
            ];
          };
        };
      }
    );

    stylesheet = ./transform.xsl;
    # config = builtins.toFile "nix-config.xml" (builtins.toXML [
    #   { path = "/bugtracker"; war = "/lib/atlassian-jira.war"; }
    #   { path = "/wiki"; war = "/uberwiki.war"; }
    # ]);
  }
  ''
    cp "$config" $out
  ''
