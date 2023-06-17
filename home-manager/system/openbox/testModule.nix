let
  pkgs = import <nixpkgs> { };
in
with pkgs.lib;
let
  cfg = (evalModules {
    modules = [
      ({ ... }: { _module.args.pkgs = pkgs; })
      (import ./default.nix)
      (testConfig)
    ] ++ hmModules;
    specialArgs = {
      modulesPath = hmModulesPath;
    };
  });
  hmPath = <home-manager>;
  hmModulesPath = "${hmPath}/modules/modules.nix";
  extendedLib = import "${hmPath}/modules/lib/stdlib-extended.nix" pkgs.lib;
  hmModules = import hmModulesPath {
    check = true;
    pkgs = pkgs;
    lib = extendedLib;
  };

  testConfig = { config, lib, pkgs, ... }: {
    xsession.windowManager.openbox = {
      enable = true;
      applications = [
        { class = "dzen"; name = "dzen2";
          layer = "below";
        }
        { class = "*";
          decor = false;
        }
      ];
      desktops = {
        number = 4;
        firstDesk = 1;
        names = [
          "desktop 1"
          "desktop 2"
        ];
        popupTime = 875;
      };
      keyboard = {
        rebindOnMappingNotify = true;
        chainQuitKey = "C-g";
        keybind = {
          "W-A-F1" = [
            { action = "desktop";
              desktop = 1;
            }
          ];
          "W-A-F2" = [
            { action = "desktop";
              desktop = 2;
            }
          ];
          "A-F4" = [
            "close"
          ];
          "A-space" = [
            { action = "showMenu";
              menu = "client-menu";
            }
          ];
          "W-A-t" = [
            { action = "execute";
              command = "urxvtc";
              startupnotify = {
                enabled = true;
                name = "URxvt client";
              };
            }
          ];
        };
      };
      focus = {
        focusNew = true;
        followMouse = false;
        focusLast = true;
        underMouse = false;
        focusDelay = 200;
        raiseOnFocus = false;
      };
      mouse = {
        mousebind = {
          "titlebar top right bottom left tLCorner tRCorner bRCorner bLCorner" = [
            { button = "Left"; action = "press";
              actions = [
                { action = "focus"; }
                { action = "raise"; }
                { action = "unshade"; }
              ];
            }
          ];
          "top" = [
            { button = "Middle"; action = "press";
              actions = [
                { action = "lower"; }
                { action = "focusToBottom"; }
              ];
            }
          ];
        };
      };
    };
  };
in cfg
