{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    escapeShellArg
    generators
    isList
    isString
    listToAttrs
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalString
    types
    ;
  cfg = config.sn.programs.pqiv;

  toOptionsIni =
    attrs:
    generators.toINI {
      mkKeyValue = generators.mkKeyValueDefault {
        mkValueString =
          v:
          if v == true then
            "1"
          else if v == false then
            "0"
          else if isString v then
            "\"${v}\""
          else
            generators.mkValueStringDefault { } v;
      } "=";
    } { options = attrs; };

  toKeyBindingsIni =
    attrs:
    generators.toINI {
      mkKeyValue = generators.mkKeyValueDefault {
        mkValueString = v: if isString v then "{ ${v}; }" else "{ ${concatStringsSep "; " v} }";
      } " ";
    } { keybindings = attrs; };

  toActionsSection = actions: ''
    [actions]
    ${concatStringsSep "\n" actions}
  '';
in
{
  options = {
    sn.programs.pqiv = {
      enable = mkEnableOption "pqiv";
      package = mkOption {
        type = with types; package;
        default = pkgs.pqiv;
        description = ''
          The base pqiv package to use
        '';
      };
      mimeTypesFromBackends = mkOption {
        type = with types; either bool (listOf str);
        default = [
          "archive_cbx"
          "gdkpixbuf"
          "spectre"
          "wand"
          "webp"
        ];
        description = ''
          Can be set to either a boolean, or a list of the backends whose mime
          types pqiv should be associated with, by using `xdg.mimeApps`.

          If set to true, loads associates with the mime types for all
          available backends. If set to false, assocaites with none of them.
        '';
      };
      settings = mkOption {
        default = { };
        description = ''
          pqiv configuration options. All long-form parameters to pqiv are
          valid settings keys.
        '';
        example = literalExpression {
          fullscreen = true;
          hide-info-box = true;
          scale-images-up = true;
          sort = true;
        };
        type = types.submodule {
          freeformType = with types; attrsOf (either str (either bool (either int (listOf str))));
        };
      };
      # TODO recursively-defined keybind value type?
      keyBindings = mkOption {
        default = { };
        example = literalExpression {
          z = "goto_file_relative(-1)";
          x = "goto_file_relative(1)";
          q = "send_keys(#1)";
          "<numbersign>1" = [
            "set_scale_level_absolute(1.)"
            "bind_key(q {send_keys(#2\\); })"
          ];
          "<numbersign>2" = [
            "set_scale_level_absolute(.5)"
            "bind_key(q {send_keys(#3\\); })"
          ];
          "<numbersign>3" = [
            "set_scale_level_absolute(0.25)"
            "bind_key(q {send_keys(#1\\); })"
          ];
          Page_Up = "goto_file_relative(-1)";
          Page_Down = "goto_file_relative(1)";
        };
        description = ''
          Maps key sequences to either individual pqiv commands, or lists of
          commands, to be executed when the key sequence is pressed. See pqiv's
          man page for details.

          Key sequences consist of lists of GDK key specifiers, as shown by
          `xev` and listed here
          https://gitlab.gnome.org/GNOME/gtk/-/blob/main/gdk/gdkkeysyms.h
        '';
        type = with types; attrsOf (either str (listOf str));
      };
      actions = mkOption {
        default = [ ];
        example = literalExpression [
          "flip_vertically()"
        ];
        description = ''
          A list of actions to be executed in order each time pqiv is started.
        '';
        type = with types; listOf str;
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];
    xdg.mimeApps.defaultApplications = listToAttrs (
      map (mime: nameValuePair mime "pqiv.desktop") (
        builtins.fromJSON (
          builtins.readFile (
            pkgs.runCommand "pqiv-backend-mimetypes"
              {
                pqivSrc = cfg.package.src;
                nativeBuildInputs = [ pkgs.jq ];
              }
              (
                let
                  mimeFiles = concatMapStringsSep " " (fileName: "\"$pqivSrc\"/backends/${fileName}") baseMimeFiles;
                  baseMimeFiles =
                    if isList cfg.mimeTypesFromBackends then
                      map (mimeType: escapeShellArg "${mimeType}.mime") cfg.mimeTypesFromBackends
                    else
                      [ "*.mime" ];
                in
                ''
                  touch "$out"
                  set -x
                  ${optionalString (cfg.mimeTypesFromBackends != false) ''
                    cat ${mimeFiles} | sort -u | jq -R . | jq -s . > "$out"
                  ''}
                ''
              )
          )
        )
      )
    );
    xdg.configFile."pqivrc".text =
      optionalString (cfg.settings != { }) (toOptionsIni cfg.settings)
      + optionalString (cfg.actions != [ ]) (toActionsSection cfg.actions)
      # NOTE: The keybindings section must be last in the file, or pqiv will
      # attempt to interpret the other section entries as keybindings
      + optionalString (cfg.keyBindings != { }) (toKeyBindingsIni cfg.keyBindings);
  };
}
