{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.sn.programs.nnn;
  plugName =
    pluginPath:
    let
      pathStr = builtins.unsafeDiscardStringContext pluginPath;
    in
    if isStorePath pluginPath then substring 44 (stringLength pathStr) pathStr else baseNameOf pathStr;
in
{
  options = {
    sn.programs.nnn = {
      enable = mkEnableOption "installing nnn with plugins";
      plugins = mkOption {
        type = with types; attrsOf (either path str);
        default = { };
        description = ''
          An attribute set mapping plugin shortcuts to plugin paths, which will
          be linked into the nnn plugin directory and added to the NNN_PLUG
          variable given to nnn.
        '';
      };
      package = mkOption {
        type = with types; package;
        default = pkgs.nnn;
        description = ''
          The base nnn package to use.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    # Create the NNN_PLUG-wrapped nnn package
    home.packages = [
      (pkgs.symlinkJoin {
        inherit (cfg.package) name src meta;
        paths = [ cfg.package ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild =
          let
            plugLine = concatStringsSep ";" (flip mapAttrsToList cfg.plugins (n: v: "${n}:${plugName v}"));
          in
          ''
            wrapProgram $out/bin/nnn \
              --prefix NNN_PLUG ";" "${plugLine}"
          '';
      })
    ];
    # Populate .config/nnn/plugins
    xdg.configFile = listToAttrs (
      flip map (attrValues cfg.plugins) (
        pluginPath:
        let
        in
        {
          name = "nnn/plugins/${plugName pluginPath}";
          value = {
            source = pluginPath;
          };
        }
      )
    );
  };
}
