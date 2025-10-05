{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    escapeShellArgs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    singleton
    types
    ;
  cfg = config.programs.yabridge;

  cfgFilePath = "${config.xdg.configHome}/yabridgectl/config.toml";
  pluginDirName = "yabridge-hm";
  pluginDirPath = "${config.xdg.dataHome}/${pluginDirName}";
in
{
  options.programs.yabridge = {
    enable = mkEnableOption "yabridge VST2/3 plugin compatibility layer";
    package = mkOption {
      type = with types; package;
      default = pkgs.yabridge;
      description = ''
        The yabridge package to use.
      '';
    };
    packageCtl = mkOption {
      type = with types; package;
      default = pkgs.yabridgectl;
      description = ''
        The yabridgectl package to use.
      '';
    };
    pluginDirs = mkOption {
      type = with types; listOf path;
      default = [ ];
      description = ''
        List of directories containing VST2/3 plugins to install via yabridge.
      '';
    };
    pluginFiles = mkOption {
      type = with types; attrsOf path;
      default = { };
      description = ''
        An attribute set describing VST2/3 plugin files to install via
        yabridge. Maps intended final plugin file names to the paths at which they exist.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.dataFile.${pluginDirName} = {
      recursive = true;
      source = pkgs.symlinkJoin {
        name = "hm-yabridge-plugin-dir";
        paths =
          cfg.pluginDirs
          ++ singleton (
            pkgs.runCommandNoCC "hm-yabridge-pluginfiles-dir"
              {
                preferLocalBuild = true;
              }
              ''
                mkdir -p $out
                ${concatMapStringsSep "\n" (
                  { name, value }:
                  ''
                    ln -s ${escapeShellArg value} "$out"/${escapeShellArg name}
                  ''
                ) (mapAttrsToList nameValuePair cfg.pluginFiles)}
              ''
          );
      };
    };
    home.packages = [
      cfg.package
      cfg.packageCtl
    ];
    home.activation.yabridge-sync =
      let
        jq = "${pkgs.jq}/bin/jq";
        sponge = "${pkgs.moreutils}/bin/sponge";
        yabridgectl = "${cfg.packageCtl}/bin/yabridgectl";
        yj = "${pkgs.yj}/bin/yj";
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Subshell to avoid polluting wider script environment
        (
          if [[ -f /etc/set-environment ]]; then
            # On NixOS, reset the environment to ensure we have NIX_PROFILES,
            # even if we've logged in non-interactively e.g. over ssh during a
            # deploy-rs activation
            . /etc/set-environment
          fi

          set -eEo pipefail
          shopt -s inherit_errexit nullglob

          function debug_log() {
            if [[ -v VERBOSE ]]; then
              echo DEBUG: "$@"
            fi
          }

          if [[ -v VERBOSE ]] && [[ "$VERBOSE" == 2 ]]; then
            set -x
          fi

          YABRIDGECTL_CONFIG_FILE=${escapeShellArg cfgFilePath}
          HM_PLUGIN_DIR=${escapeShellArg pluginDirPath}

          function read_yabridgectl_config() {
            read_filter="$1"
            cat "$YABRIDGECTL_CONFIG_FILE" |
              ${yj} -tj |
              ${jq} -r "$read_filter"
          }

          function update_yabridgectl_config() {
            update_filter="$1"
            read_yabridgectl_config "$update_filter" |
              ${yj} -jt |
              ${sponge} "$YABRIDGECTL_CONFIG_FILE"
          }

          # Initialise yabridgectl config file, if necessary
          if ! [[ -f ~/.config/yabridgectl/config.toml ]]; then
            echo "Initialising yabridgectl configuration file"
            ${yabridgectl} status >/dev/null
          else
            debug_log "yabridgectl config file already exists, not initialising it"
          fi

          # Confirm that mode is already set to copy, or set it if not
          if [[ "$(read_yabridgectl_config '.method')" != "copy" ]]; then
            echo "Setting yabridgectl method to 'copy'"
            $DRY_RUN_CMD update_yabridgectl_config '.method = "copy"'
          else
            debug_log "yabridgectl method already set to 'copy'"
          fi

          # Get the set of existing plugin directories
          declare -A plugin_dirs
          while read -r dir; do
            debug_log "Existing plugin directory: $dir"
            plugin_dirs[$dir]=1
          done < <(read_yabridgectl_config '.plugin_dirs[]')

          # Check if the HM dir is already in the plugin list or not
          if ! [[ ''${plugin_dirs[$HM_PLUGIN_DIR]+_} ]]; then
            echo "HM-managed plugin directory not in yabridgectl config, adding it now"
            $DRY_RUN_CMD update_yabridgectl_config ".plugin_dirs[.plugin_dirs | length] |= . + \"$HM_PLUGIN_DIR\""
          else
            debug_log "HM-managed plugin directory already present in yabridgectl config"
          fi

          # Update the plugins
          echo "Updating yabridge plugin mappings"
          $DRY_RUN_CMD ${yabridgectl} sync $VERBOSE_ARG
        )
      '';
  };
}
