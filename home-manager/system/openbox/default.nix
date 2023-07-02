{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.xsession.windowManager.openbox;
  inherit (config.lib) dag;

  upperCaseFirst = str: let
    first = toUpper (substring 0 1 str);
    tail = substring 1 (stringLength str) str;
  in "${first}${tail}";

  upperCaseActions = actionList: flip map actionList
    (action: action // { action = upperCaseFirst action.action; });

  # TODO somehow integrate font packages? use package argument instead of name?
  # make name take a derivation optionally?
  fontType = { config, ... }: {
    options = {
      name = mkOption {
        type = with types; str;
        default = "sans";
        description = ''
          Specify the font to use.
        '';
      };
      size = mkOption {
        type = with types; ints.unsigned;
        default = 9;
        description = ''
          The size (in px) of the font.
        '';
      };
      weight = mkOption {
        type = with types; enum [ "normal" "bold" ];
        default = "normal";
        description = ''
          The weight of the font, either "normal" or "bold".
        '';
      };
      slant = mkOption {
        type = with types; enum [ "normal" "italic" ];
        default = "normal";
        description = ''
          The slant of the font, either "normal" or "italic".
        '';
      };
    };
  };

  mkFontOption = windowElement: default: mkOption {
    type = with types; submodule fontType;
    default = default;
    description = ''
      The font to use for the ${windowElement}.
    '';
  };

  # keyComboType = KEY-COMBINATION..., space-separated
  # KEY-COMBINATION = Modifier-Key, any number of modifiers (0+)
  keyComboPattern = "^(([SCAWMH]-)*[^[:space:]-]+ ?)+$";
  keyComboType = with types; strMatching keyComboPattern;
  # TODO confirm button5 and below are accepted, or change regex
  # mouseKeyComboPattern = "^(([SCAWMH]-)*(Left|Middle|Right|Up|Down|Button[[:digit:]]+) ?)+$";
  mouseKeyComboPattern = "^(([SCAWMH]-)*(Left|Middle|Right|Up|Down|Button[[:digit:]]+) ?)+$";
  mouseKeyComboType = with types; strMatching mouseKeyComboPattern;

  actionType = with types; addCheck (coercedTo str (coerceAction) attrs) (actionNameCheck);
  actionNameType = types.enum [
    "execute" "showMenu" "nextWindow" "previousWindow"
    "directionalCycleWindows" "directionalTargetWindow" "desktop" "goToDesktop"
    "addDesktop" "removeDesktop" "toggleShowDesktop" "toggleDockAutohide"
    "reconfigure" "restart" "exit" "sessionLogout" "debug" "focus" "raise"
    "lower" "raiseLower" "unfocus" "focusToBottom" "iconify" "close"
    "toggleShade" "shade" "unshade" "toggleOmnipresent" "toggleMaximize"
    "maximize" "unmaximize" "toggleFullscreen" "toggleDecorations" "decorate"
    "undecorate" "sendToDesktop" "move" "resize" "moveResizeTo" "moveRelative"
    "resizeRelative" "moveToEdge" "growToEdge" "growToFill" "shrinkToEdge" "if"
    "forEach" "stop" "toggleAlwaysOnTop" "toggleAlwaysOnBottom" "sendToLayer"
  ];
  coerceAction = str: { action = str; };
  actionNameCheck = action: actionNameType.check
    (if isAttrs action then action.action else action);

  nameCheckAttrsOf = nameCheck: elemType: let
    baseType = types.attrsOf elemType;
  in baseType // {
    check = x: isAttrs x && (all (nameCheck) (attrNames x));
    substSubModules = m: nameCheckAttrsOf nameCheck (elemType.substSubModules m);
  };
in
{
  _file = builtins.toString ./default.nix;
  options = {
    xsession.windowManager.openbox = {
      enable = mkEnableOption "Openbox window manager";
      prependPaths = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          List of paths to prepend to $PATH for Openbox, if the paths exist.

          Earlier items in the list will be earlier in the resulting PATH.
        '';
      };
      startupApps = mkOption {
        type = with types; attrs;
        default = {
        };
        description = ''
          DAG of scripts/programs to execute during openbox startup.

          Default synchronisation points that can be hooked with `lib.dag`:
          - cli
          - graphics
          - tray
          - app
        '';
      };
      # rc.xml options
      # TODO
      # - handle theme.fonts
      applications = mkOption {
        type = with types; listOf (submodule ({ config, ... }: {
          options = {
            # TODO assert one of the match properties is non-null
            name = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_NAME property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            class = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_CLASS property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            groupName = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_GROUP_NAME property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            groupClass = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_GROUP_CLASS property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            role = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_ROLE property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            title = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                The window's _OB_APP_TITLE property (see obxprop).

                Wildcards: * matches any sequence of characters, ? matches any
                single character.
              '';
            };
            type = mkOption {
              type = with types; nullOr
                (enum [ "normal" "dialog" "splash" "utility" "menu" "toolbar" "dock" "desktop"]);
              default = null;
              description = ''
                The window's _OB_APP_TYPE property (see obxprop).
              '';
            };
            decor = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to enable window decorations.
              '';
            };
            shade = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to make the window shaded when it appears.
              '';
            };
            focus = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to attempt to give the window focus when it
                appears. Some restrictions may apply.
              '';
            };
            desktop = mkOption {
              type = with types; either ints.positive (enum [ "default" "all" ]);
              default = "default";
              description = ''
                The desktop to the window should appear on. Can be specified as
                one of:
                - an index, starting at 1, specifying a particular desktop
                - all: appear on all desktops
                - default: use value provided by the application or chosen by Openbox
              '';
            };
            layer = mkOption {
              type = with types; enum [ "default" "above" "normal" "below" ];
              default = "default";
              description = ''
                The layer to place the window on.
              '';
            };
            iconic = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to make the window iconified when it appears.
              '';
            };
            skipPager = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to show the window in pagers.
              '';
            };
            skipTaskbar = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to show the window in taskbars. If not shown,
                window cycling actions will also skip past the window.
              '';
            };
            fullscreen = mkOption {
              type = with types; either bool (enum [ "default" ]);
              default = "default";
              description = ''
                Whether or not to show the window in fullscreen mode when it
                appears.
              '';
            };
            maximized = mkOption {
              type = with types; either bool (enum [ "default" "horizontal" "vertical" ]);
              apply = x: if isString x && x != "default" then upperCaseFirst x else x;
              default = "default";
              description = ''
                Whether or not to make the window maximized when it appears.
                Can be specified as one of:
                - horizontal: Horizontally maximized
                - vertical: Horizontally maximized
                - true/false: Fully maximized, or not maximized at all
                - default: use value provided by the application or chosen by Openbox
              '';
            };
            position = {
              force = mkOption {
                type = with types; bool;
                default = false;
                description = ''
                  Whether or not to force application positioning even when it
                  requests placement elsewhere.

                  Only applicable if both `position.x` and `position.y` are set.
                '';
              };
              x = mkOption {
                type = with types; either int (enum [ "default" "center" ]);
                apply = x: if isString x && x != "default" then upperCaseFirst x else x;
                default = "default";
                description = ''
                  The horizontal position of the window, can be specified as one of:
                  - postive integer values: pixels from the left edge of the monitor
                  - negative integer values: pixels from the right edge of the monitor
                  - center: center it on the monitor
                  - default: use value provided by the application or chosen by Openbox
                '';
              };
              y = mkOption {
                type = with types; either int (enum [ "default" "center" ]);
                apply = x: if isString x && x != "default" then upperCaseFirst x else x;
                default = "default";
                description = ''
                  The vertical position of the window, can be specified as one of:
                  - postive integer values: pixels from the top edge of the monitor
                  - negative integer values: pixels from the bottom edge of the monitor
                  - center: center it on the monitor
                  - default: use value provided by the application or chosen by Openbox
                '';
              };
              monitor = mkOption {
                type = with types; either ints.unsigned (enum [ "default" "mouse" ]);
                default = "default";
                description = ''
                  The monitor the to place the window on. Specified as one of:
                  - an index, starting at 1, specifying a particular monitor
                  - mouse: where the mouse is
                  - default: use value provided by the application or chosen by Openbox
                '';
              };
            };
            size = {
              width = mkOption {
                type = with types; oneOf [
                  ints.unsigned
                  (strMatching "^[[:digit:]]+/[[:digit:]]+$") # fractional
                  (strMatching "^[[:digit:]]{1,3}%$") # percentage
                  (enum [ "default" ])
                ];
                default = "default";
                description = ''
                  The width of the monitor. Can be specified as one of:
                  - positive integer value: width in pixels
                  - fractions (e.g. 1/2): fractional proportion of the monitor
                  - percentages (e.g. 75%): percentage proportion of the monitor
                  - default: use value provided by the application or chosen by Openbox
                '';
              };
              height = mkOption {
                type = with types; oneOf [
                  ints.unsigned
                  (strMatching "^[[:digit:]]+/[[:digit:]]+$") # fractional
                  (strMatching "^[[:digit:]]{1,3}%$") # percentage
                  (enum [ "default" ])
                ];
                default = "default";
                description = ''
                  The height of the monitor. Can be specified as one of:
                  - positive integer value: height in pixels
                  - fractions (e.g. 1/2): fractional proportion of the monitor
                  - percentages (e.g. 75%): percentage proportion of the monitor
                  - default: use value provided by the application or chosen by Openbox
                '';
              };
            };
          };
        }));
        default = [];
        description = ''
          When multiple rules match a window, they will all be applied, in the
          order they are listed.
        '';
      };
      desktops = {
        number = mkOption {
          type = with types; ints.positive;
          default = 4;
          description = ''
            The default number of desktops.

            Only used on creation of a new session, can be changed at runtime
            by pagers.
          '';
        };
        # TODO assert <= number
        firstDesk = mkOption {
          type = with types; ints.positive;
          default = 1;
          description = ''
            The default desktop to start on.

            Only used on creation of a new session, can be changed at runtime
            by pagers.
          '';
        };
        names = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            The names of the default desktops.

            Only used on creation of a new session, can be changed at runtime
            by pagers.
          '';
        };
        popupTime = mkOption {
          type = with types; ints.unsigned;
          default = 875;
          description = ''
            Amount of time (in milliseconds) to show a popup for when switching
            desktops. Set to 0 to disable the popup.
          '';
        };
      };
      # dock = {
      #   position = mkOption {
      #     type = with types; enum [
      #       "top" "bottom" "left" "right" # sides
      #       "topLeft" "topRight" "bottomLeft" "bottomRight" # corners
      #       "floating"
      #     ];
      #     default = "topLeft";
      #     description = ''
      #       Specify where to show the dock:
      #       - top, bottom, left, right: Centered on the specified side of the
      #         screen
      #       - topleft, topRight, bottomLeft, bottomRight: In the specified
      #         corner of the screen
      #       - floating: In the position specified by the `dock.floatingX` and
      #         `dock.floatingY` options
      #     '';
      #   };
      #   floatingX = mkOption {
      #     type = with types; int.unsigned;
      #     default = 0;
      #     description = ''
      #       Horizontal position of the dock in pixels from the left edge of the
      #       screen.

      #       Only applicable if `dock.position` is set to "floating".
      #     '';
      #   };
      #   floatingY = mkOption {
      #     type = with types; int.unsigned;
      #     default = 0;
      #     description = ''
      #       Vertical position of the dock in pixels from the top edge of the
      #       screen.

      #       Only applicable if `dock.position` is set to "floating".
      #     '';
      #   };
      #   noStrut = mkOption {
      #     type = with types; bool;
      #     default = false;
      #     description = ''
      #       Whether or not the dock should set a strut, which would prevent
      #       windows from being placed or maximized over it. This is always
      #       enabled if `dock.position` is set to "floating".
      #     '';
      #   };
      #   stacking = mkOption {
      #     type = with types; enum [ "above" "normal" "below" ];
      #     default = "above";
      #     description = ''
      #       Which window layer to put the dock in. The dock can be raised and
      #       lowered among windows in the same layer, by left and middle
      #       clicking on it.
      #     '';
      #   };
      #   direction = mkOption {
      #     type = with types; enum [ "vertical" "horizontal" ];
      #     apply = x: upperCaseFirst;
      #     default = "vertical";
      #     description = ''
      #       Specify which direction dock apps should be laid out in.
      #     '';
      #   };
      #   autoHide = mkOption {
      #     type = with types; bool;
      #     default = false;
      #     description = ''
      #       Whether or not the dock should hide automatically when the mouse is
      #       not over it.
      #     '';
      #   };
      #   hideDelay = mkOption {
      #     type = with types; ints.unsigned;
      #     default = 300;
      #     description = ''
      #       The delay (in milliseconds) after which the dock will be hidden,
      #       after the mouse has left it.
      #     '';
      #   };
      #   showDelay = mkOption {
      #     type = with types; ints.unsigned;
      #     default = 300;
      #     description = ''
      #       The delay (in milliseconds) after which the dock will be shown,
      #       after the mouse has entered it.
      #     '';
      #   };
      #   moveButton = mkOption {
      #     type = with types; enum [ "left" "middle" "right" ];
      #     default = "middle";
      #     description = ''
      #       The button to use for moving individual dock apps around in the
      #       dock.
      #     '';
      #   };
      # };
      focus = {
        focusNew = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to give focus to new windows when they are created.
          '';
        };
        followMouse = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not window focus should follow the mouse (e.g. when the
            mouse cursor is moved, focus is given to whatever window is under
            the cursor).
          '';
        };
        focusDelay = mkOption {
          type = with types; ints.unsigned;
          default = 200;
          description = ''
            The time (in milliseconds) Openbox will wait before giving focus to
            the window under the mouse cursor.

            Only applicable if `focus.followMouse` is set.
          '';
        };
        focusLast = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            When switching desktops, whether or not to focus on the
            last-focused window for that desktop again, regardless of where the
            mouse currently is.

            Only applicable if `focus.followMouse` is set.
          '';
        };
        underMouse = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not to focus windows under the mouse not only when the
            mouse moves, but also when it enters another window due to some
            other reason (e.g. the window the mouse was in
            moved/closed/minimised).

            Only applicable if `focus.followMouse` is set.
          '';
        };
        raiseOnFocus = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not to raise windows to the top of the window stack when
            they are focused.

            Only applicable if `focus.followMouse` is set.
          '';
        };
      };
      keyboard = {
        rebindOnMappingNotify = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to rebind keybinds if the keyboard layout changes at
            runtime.
          '';
        };
        chainQuitKey = mkOption {
          type = keyComboType;
          default = "C-g";
          description = ''
            The keybind to use to cancel a key chain.
          '';
        };
        keybind = mkOption {
          type = with types; nameCheckAttrsOf
            (x: keyComboType.check x)
            (listOf actionType);
          default = {};
          # TODO example
          example = literalExpression ''
            {
              "C-A-Left" = [
                { action = "GoToDesktop";
                  to = "right";
                  wrap = "no";
                }
              ];
            }
          '';
          description = ''
            Global keyboard shortcut bindings.
          '';
        };
      };
      margins = {
        top = mkOption {
          type = with types; ints.unsigned;
          default = 0;
          description = ''
            Pixels from the top of the screen to 'reserve', preventing windows
            from maximizing into it or new windows being placed into it by
            default.
          '';
        };
        bottom = mkOption {
          type = with types; ints.unsigned;
          default = 0;
          description = ''
            Pixels from the bottom of the screen to 'reserve', preventing windows
            from maximizing into it or new windows being placed into it by
            default.
          '';
        };
        left = mkOption {
          type = with types; ints.unsigned;
          default = 0;
          description = ''
            Pixels from the left of the screen to 'reserve', preventing windows
            from maximizing into it or new windows being placed into it by
            default.
          '';
        };
        right = mkOption {
          type = with types; ints.unsigned;
          default = 0;
          description = ''
            Pixels from the right of the screen to 'reserve', preventing windows
            from maximizing into it or new windows being placed into it by
            default.
          '';
        };
      };
      menu = {
        file = mkOption {
          type = with types; listOf str;
          default = singleton "menu.xml";
          # TODO integration for menus?
          description = ''
            Paths to the menu files to load from.
          '';
        };
        hideDelay = mkOption {
          type = with types; ints.unsigned;
          default = 200;
          description = ''
            Amount of time (in milliseconds) that a press-release must last
            longer than in order for the menu to re-hide itself on release.
          '';
        };
        middle = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not to center submenus vertically about the parent entry.
          '';
        };
        submenuShowDelay = mkOption {
          type = with types; int;
          default = 100;
          description = ''
            Amount of time (in milliseconds) to delay before showing a submenu
            while hovering over the parent entry.

            If set to a negative value, then the delay is effectively infinite,
            and the submenu will not be shown until and unless it is clicked
            on.
          '';
        };
        submenuHideDelay = mkOption {
          type = with types; int;
          default = 400;
          description = ''
            Amount of time (in milliseconds) to delay before hiding a submenu
            when hovering over another entry in the parent menu.

            If set to a negative value, then the delay is effectively infinite,
            and the submenu will not be hidden until and unless another submenu
            is opened.
          '';
        };
        showIcons = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not icons appear in the client-list-(combined-)menu.
          '';
        };
        manageDesktops = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to show the manage desktops section in the
            client-list-(combined-)menu.
          '';
        };
      };
      mouse = {
        dragThreshold = mkOption {
          type = with types; ints.unsigned;
          default = 8;
          description = ''
            The number of pixels the mouse must move before a drag begins.
          '';
        };
        doubleClickTime = mkOption {
          type = with types; ints.unsigned;
          default = 200;
          description = ''
            The maximum time (in milliseconds) between two clicks for a
            double-click.
          '';
        };
        screenEdgeWarpTime = mkOption {
          type = with types; ints.unsigned;
          default = 400;
          description = ''
            The time (in milliseconds) before changing desktops when the
            pointer touches the edge of the screen while moving a window.

            Set to 0 to disable screen edge warping.
          '';
        };
        screenEdgeWarpMouse = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not to move the mouse pointer across the desktop when
            switching due to hitting the edge of the screen.

            Only applicable if `mouse.screenEdgeWarpTime` is greater than 0.
          '';
        };
        mousebind = let
          contextType' = types.addCheck (types.attrsOf mousebindListType) (x: false);
          contextType = nameCheckAttrsOf (contextCheck) mousebindListType // {
            description = baseType.description +
              ", where attribute names are space-separated lists of valid mousebind contexts";
          };
          contextCheck = name: let
            contextNameList = (splitString " " name);
            checks = map (contextNameType.check) contextNameList;
          in foldl' (a: b: a && b) true (checks);
          contextNameType = types.enum [
            "frame" "client" "desktop" "root" "titlebar"
            "top" "bottom" "left" "right"
            "tLCorner" "tRCorner" "bLCorner" "bRCorner"
            "icon" "iconify" "maximize" "close" "allDesktops" "shade"
            "moveResize"
          ];
          mousebindListType = with types; listOf mousebindType;
          mousebindType = types.submodule {
            options = {
              button = mkOption {
                type = mouseKeyComboType;
                description = ''
                  The mouse button to bind against:
                  - Left, Right, Middle: The left, right, and middle mouse buttons
                  - Up, Down: Scroll wheel up and down
                  The buttons can be prefixed with modifier keys, similarly to
                  keyboard binds, e.g. "A-Left".

                  To bind more than 5 buttons, use "Button6", "Button7", etc.
                '';
              };
              action = mkOption {
                type = with types; enum [ "press" "click" "doubleClick" "release" "drag" ];
                apply = upperCaseFirst;
                description = ''
                  The mouse event that triggers the action:
                  - press: the mouse button was pressed down in the specified context
                  - click: the mouse button was pressed and released in the specified
                    context
                  - doubleClick: the mouse button was double clicked in the specified
                    context
                  - release: the mouse button was released in the specified context
                  - drag: the mouse was dragged with the mouse button held down in the
                    specified context
                '';
              };
              actions = mkOption {
                type = with types; listOf actionType;
                apply = upperCaseActions;
                description = ''
                  The list of actions to perform in order, on triggering this
                  keybind.
                '';
              };
            };
          };
        in mkOption {
          # NOTE: Custom mkOptionType, basically an attrsOf with extra
          # type-checking/coercing on the names of attributes
          type = contextType;
          default = {};
          # TODO example
          # TODO assertion on "press" event limitation in client context
          # TODO is the moveResize context limited to drag events? release?
          description = ''
            Defines mouse binds within given sets of contexts. Attribute names
            should be a space-separated set of contexts, attribute values are
            lists of mouse bindings within the specified set of contexts.

            Valid contexts:
            - frame: the entire window frame for any window (except the
              desktop). This includes both the window decorations (if any) and
              the application window itself. Any buttons bound in this context
              will *not* be passed through to the application; use with care
            - client: the application window, inside the window decorations.
              Buttons bound in this context *will* be passed through to the
              aplication, but because of this, only "press" events can be used
              in this context.
            - desktop: the desktop, or background, regardless of if you use a
              program to place icons on your desktop or not. This is also known
              as the "root window"
            - root: similar to the desktop context, however it is triggered
              only when you *don't* use a program to place icons on your
              desktop.  Generally this is only used for the root menus, to
              prevent them overriding the menus provided by your desktop icons
            - titlebar: the decorations on the top of each application window
            - top: the top eddge of a window
            - bottom: the bottom eddge of a window
            - left: the left eddge of a window
            - right: the right eddge of a window
            - tLCorner: the top-left corner of a window
            - tRCorner: the top-right corner of a window
            - bLCorner: the bottom-left corner of a window
            - bRCorner: the bottom-right corner of a window
            - icon: the window icon shown in window titlebars
            - iconify: the iconify button shown in window titlebars
            - maximize: the maximize button shown in window titlebars
            - close: the close button shown in window titlebars
            - allDesktops: the allDesktops button shown in window titlebars
            - shade: the shade button shown in window titlebars
            - moveResize: a special context available while a window is being
              moved or resized interactively
          '';
        };
      };
      placement = {
        policy = mkOption {
          type = with types; enum [ "smart" "underMouse" ];
          default = "smart";
          apply = upperCaseFirst;
          description = ''
            The policy for placement of new windows. The options are:
            - smart: New windows will be placed with their position dynamically
              determined by Openbox.
            - underMouse: New windows will be placed under the mouse cursor.
          '';
        };
        center = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Whether or not to center new windows in the free area found for
            placement.
          '';
        };
        monitor = mkOption {
          type = with types; enum [ "primary" "mouse" "active" "any" ];
          apply = upperCaseFirst;
          default = "primary";
          description = ''
            With smart placement on a multi-monitor system, try to place new
            windows on:
            - any: any monitor
            - mouse: where the mouse is
            - active: where the active window is
            - primary: on the primary monitor
          '';
        };
        primaryMonitor = mkOption {
          type = with types; either ints.positive (enum [ "mouse" "active" ]);
          apply = x: if isString x then upperCaseFirst x else x;
          default = 1;
          description = ''
            The primary monitor, which is where Openbox will place popup dialogs such as the focus cycling group, or the desktop switch popup.

            Provided as one of:
            - an index, starting at 1, specifying a particular monitor
            - mouse: where the mouse is
            - active: where the active window is
          '';
        };
      };
      resistance = {
        strength = mkOption {
          type = with types; ints.unsigned;
          default = 10;
          description = ''
            How much resistance (in pixels) there is to overlapping one window
            on another when moving one.
          '';
        };
        screenEdgeStrength = mkOption {
          type = with types; ints.unsigned;
          default = 20;
          description = ''
            How much resistance (in pixels) there is to moving a window's edge
            beyond a screen edge.
          '';
        };
      };
      resize = {
        drawContents = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Actively resize the program inside the window when resizing the
            window. When disabled, unused space will be filled with a uniform
            colour during a resize.
          '';
        };
        popupShow = mkOption {
          type = with types; enum [ "always" "never" "nonpixel" ];
          apply = upperCaseFirst;
          default = "nonpixel";
          description = ''
            When to show the resize popup:
            - always: always show it
            - never: never show it
            - nonpixel: show it only when resizing windows that have specified
              they are resized in increments larger than one pixel (e.g.
              terminals that resize in units of one character)
          '';
        };
        popupPosition = mkOption {
          type = with types; enum [ "center" "top" "fixed" ];
          apply = upperCaseFirst;
          default = "center";
          description = ''
            Where to show the popup:
            - center: centered on the window being resized
            - top: above the titlebar of the window
            - fixed: in a fixed location on the screen, specified by
              `resize.popupFixedPosition`
          '';
        };
        popupFixedPosition = {
          x = mkOption {
            type = with types; either int (enum [ "center" ]);
            apply = x: if isString x then upperCaseFirst x else x;
            default = 10;
            description = ''
              Specify the horizontal position on the screen as:
              - positive integer values for pixels from left edge
              - negative integer values for pixels from right edge
              - "center" for the horizontal center of the screen

              Only applicable if `resize.popupPosition` is set to "fixed".
            '';
          };
          y = mkOption {
            type = with types; either int (enum [ "center" ]);
            apply = x: if isString x then upperCaseFirst x else x;
            default = 10;
            description = ''
              Specify the vertical position on the screen as:
              - positive integer values for pixels from top edge
              - negative integer values for pixels from bottom edge
              - "center" for the vertical center of the screen

              Only applicable if `resize.popupPosition` is set to "fixed".
            '';
          };
        };
      };
      theme = {
        name = mkOption {
          type = with types; str; # TODO structured type here? Or better yet, take a derivation and link in the path, transform the name?
          default = "cathexis";
          description = ''
            The name of the Openbox theme to use.
          '';
        };
        titleLayout = mkOption {
          # TODO find out of they can safely be duplicated, or if we need an
          # assert in there
          type = with types; listOf (enum [ "N" "L" "I" "M" "C" "S" "D" ]);
          default = [ "N" "S" "L" "D" "I" "M" "C" ];
          # Merge the list to a string
          apply = x: concatStrings x;
          description = ''
            Specify the selection and order of items present in a window's
            titlebar. The following types of specifier are available:
            - N: window icon
            - L: window label/title
            - I: iconify
            - M: maximize
            - C: close
            - S: shade (roll up/down into titlebar)
            - D: omnipresent (on all desktops)
          '';
        };
        keepBorder = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not windows should keep the border drawn by Openbox even
            when they've turned off window decorations (e.g. Chromium turns off
            window decorations).
          '';
        };
        animateIconify = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            Whether or not to animate the iconification process.
          '';
        };
        fonts = {
          activeWindow = mkFontOption
            "title bar of an active window" { size = 8; weight = "bold"; };
          inactiveWindow = mkFontOption
            "title bar of an inactive window" { size = 8; weight = "bold"; };
          menuHeader = mkFontOption
            "titles in the right-click menu" { };
          menuItem = mkFontOption
            "items in the right-click menu" { };
          activeOnScreenDisplay = mkFontOption
            "text in active popups (e.g. window cycling or desktop switching popups)"
            { weight = "bold"; };
          inactiveOnScreenDisplay = mkFontOption
            "text in inactive popups (e.g. window cycling or desktop switching popups)"
            { weight = "bold"; };
        };
      };
      # Internal implementation detail
      transformedConfig = mkOption {
        type = with types; attrs;
        readOnly = true;
        internal = true;
        visible = false;
      };
      rawConfigFile = mkOption {
        type = with types; path;
        readOnly = true;
        internal = true;
        visible = false;
      };
      finalConfigFile = mkOption {
        type = with types; path;
        readOnly = true;
        internal = true;
        visible = false;
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      openbox
    ];

    # TODO abstract much of this outside of openbox?
    xsession.windowManager.command = let
      GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" [
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-libav
      ];
      cmd = with pkgs; writeShellScript "openbox-startup.sh" ''
        # Set GTK_DATA_PREFIX so that GTK+ can find the themes
        export GTK_DATA_PREFIX=/run/current-system/sw/:~/.local/share/themes

        # Find theme engines
        export GTK_PATH=/run/current-system/sw/lib/gtk-3.0:/run/current-system/sw/lib/gtk-2.0

        # Find mouse icons
        export XCURSOR_PATH=~/.icons:/run/current-system/sw/share/icons

        export GST_PLUGIN_PATH="${GST_PLUGIN_PATH}"

        # Override default mimeapps
        export XDG_DATA_DIRS=$XDG_DATA_DIRS''${XDG_DATA_DIRS:+:}:/run/current-system/sw/share

        # Update user dirs as described in http://freedesktop.org/wiki/Software/xdg-user-dirs/
        ${xdg-user-dirs}/bin/xdg-user-dirs-update

        ${openbox}/bin/openbox-session
      '';
    in toString cmd;

    xsession.windowManager.openbox.startupApps = {
      cli = dag.entryAnywhere null;
      graphics = dag.entryAfter [ "cli" ] null;
      tray = dag.entryAfter [ "graphics" ] null;
      app = dag.entryAfter [ "tray" ] null;
    };

    xdg.configFile = {
      "openbox/environment".text = ''
        #!${pkgs.bash}/bin/bash
        # TODO pull environment variables to set from an array?
        # We're not LXDE, but it defaults to using openbox, so this is the
        # closest oft-recognised match. TODO make this configurable?
        XDG_CURRENT_DESKTOP="lxde"
      '' + concatMapStringsSep "\n" (path: ''
        if [[ -d ${path} ]]; then
          export PATH="${path}''${PATH:+:''${PATH}}"
        fi
      '') (reverseList cfg.prependPaths);

      "openbox/autostart".text = ''
        #!${pkgs.bash}/bin/bash
        # The `(launch stuff) & wait` construct is a bit of a hack, here's how it works:
        # - (): defines a top-level subshell within the script, & to background it.
        # - wait: waits for all backgrounded processes in the current shell to finish,
        #         i.e. wait on the subshell to finish.
        # - launch stuff: launches things within the subshell, the launched scripts
        #                 should background whatever they start.
        # The subshell should end while the launched stuff within it is still alive,
        # due to the double-forking from backgrounding.

        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XDG_SESSION_ID XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
        ${pkgs.systemd}/bin/systemctl --user start openbox-graphical-session.target
      '' + concatMapStringsSep "\n"
        ({ data, name }: ''
          # Launching ${name}
          (
            sh "${data}" &
          ) & wait
        '')
        (filter ({data, name}: data != null) (dag.topoSort cfg.startupApps).result);

      "openbox/rc.xml" = {
        source = config.xsession.windowManager.openbox.finalConfigFile;
        onChange = ''
          # Attempt to reconfigure openbox if X is running.
          if systemctl --user is-active openbox-graphical-session.target >/dev/null; then
            echo "Reconfiguring openbox"
            if [[ -v DISPLAY ]]; then
              $DRY_RUN_CMD ${pkgs.openbox}/bin/openbox --reconfigure
            fi
          fi
        '';
      };
    };

    # Generate final configuration file
    xsession.windowManager.openbox.transformedConfig = let
      transformedConfig = strippedConfig // {
        resistance = {
          inherit (strippedConfig.resistance) strength;
          screen_edge_strength = strippedConfig.resistance.screenEdgeStrength;
        };
        applications = map (transformApp) strippedConfig.applications;
        desktops = {
          inherit (strippedConfig.desktops) number names popupTime;
          firstdesk = strippedConfig.desktops.firstDesk;
        };
        mouse = strippedConfig.mouse // {
          mousebind = mapAttrs' (transformMousebind) strippedConfig.mouse.mousebind;
        };
        keyboard = strippedConfig.keyboard // {
          keybind = mapAttrs (transformKeybind) strippedConfig.keyboard.keybind;
        };
        theme = strippedConfig.theme // {
          fonts = flip mapAttrs' strippedConfig.theme.fonts (name: value:
            nameValuePair (upperCaseFirst name) value);
        };
      };
      transformApp = app: (removeAttrs app [
        "groupName" "groupClass"
        "skipPager" "skipTaskbar"
      ]) // {
        groupname = app.groupName; groupclass = app.groupClass;
        skip_pager = app.skipPager; skip_taskbar = app.skipTaskbar;
      };
      transformMousebind = name: value: nameValuePair
        (concatStringsSep " " (map (upperCaseFirst) (splitString " " name)))
        value;
      transformKeybind = _name: value: upperCaseActions value;
      strippedConfig = removeAttrs cfg [
        "enable" "prependPaths" "startupApps"
        "rawConfigFile" "finalConfigFile" "transformedConfig"
      ];
    in transformedConfig;
    xsession.windowManager.openbox.rawConfigFile = pkgs.writeText "raw-config.xml"
      (builtins.toXML config.xsession.windowManager.openbox.transformedConfig);
    xsession.windowManager.openbox.finalConfigFile = pkgs.runCommand "rc.xml" {
      preferLocalBuild = true;
      nativeBuildInputs = with pkgs; [
        saxonb_9_1
        libxml2
      ];
      inherit (config.xsession.windowManager.openbox) rawConfigFile;
    } ''
      saxonb "$rawConfigFile" ${./transform.xsl} | xmllint --format - > $out
    '';
    systemd.user.targets.openbox-graphical-session = {
      Unit = {
        Description = "Openbox Xorg session";
        BindsTo = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
    };
  };
}
