{ config, lib, pkgs, ... }:
let
  cfg = config.programs.eww;
  inherit (lib) concatStringsSep literalExpression mkEnableOption mkIf mkMerge mkOption optionalString types;
in
{
  disabledModules = [
    "programs/eww.nix"
  ];

  options.programs.eww = {
    enable = mkEnableOption "ElKowars wacky widgets";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      defaultText = literalExpression "pkgs.eww";
      example = literalExpression "pkgs.eww";
      description = ''
        The eww package to install.
      '';
    };

    configDir = mkOption {
      type = types.path;
      example = literalExpression "./eww-config-dir";
      description = ''
        The directory that gets used as the source for
        <filename>''${config.home.homeDirectory}/eww</filename>.
      '';
    };

    # TODO: Create a dev-shell package that includes all of the packages in PATH
    devMode = mkOption {
      type = types.bool;
      example = literalExpression "true";
      default = false;
      description = ''
        Whether or not to enable dev mode, which will add NixOS system-wide and
        home-manager's paths to the PATH used by the service.
      '';
    };

    runtimeDeps = mkOption {
      type = with types; listOf package;
      default = [];
      description = ''
        A list of the packages that your eww configuration will make use of at
        runtime.
      '';
    };

    windows = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        A list of eww windows to open on startup;
      '';
    };
  };

  config = let
    eww = "${config.programs.eww.package}/bin/eww";
  in mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];
      xdg.configFile."eww".source = if !cfg.devMode
        then cfg.configDir
        else config.lib.file.mkOutOfStoreSymlink cfg.configDir;
      systemd.user.services.eww = {
        Unit = {
          Description = "ElKowars Wacky Widgets daemon";
          PartOf = [ "hm-graphical-session.target" ];
        };
        Service = {
          Environment = let
            runtimePackages = [
              cfg.package # Not sure this is needed, given EWW_COMMANd 'magic variable' should expand to the full path of the running binary?
              pkgs.bash # eww depends on having a `sh` available at runtime
            ] ++ cfg.runtimeDeps;
          in if !cfg.devMode
            then "PATH=/run/wrappers/bin:${lib.makeBinPath runtimePackages}"
            else "PATH=/run/wrappers/bin:${lib.makeBinPath runtimePackages}:${config.lib.sn.makePath config.lib.sn.baseUserPath}";
          ExecStart = "${eww} daemon --no-daemonize" + optionalString cfg.devMode " --debug";
          Restart = "on-abnormal";
          Slice = "session.slice";
        };
        Install.WantedBy = [ "hm-graphical-session.target" ];
      };
    })
    # Openbox window-opening implementation
    (mkIf (cfg.enable && config.xsession.windowManager.openbox.enable && (cfg.windows != [])) {
      xsession.windowManager.openbox.startupApps = with config.lib.openbox; listToAttrs [
        (launchApp "eww-windows" ''
          if ${pkgs.systemd}/bin/systemctl --user is-active eww.service >/dev/null; then
            ${eww} open-many ${concatStringsSep " " cfg.windows}
          fi
        '')
      ];
    })
  ];
}
