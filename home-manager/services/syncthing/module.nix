{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.syncthing;


  devices = mapAttrsToList
    (name: device: {
      deviceID = device.id;
      inherit (device) name addresses introducer;
    })
    (filterAttrs (n: v: n != cfg.thisDevice) cfg.declarative.devices);

  folders = mapAttrsToList ( _: folder: {
    inherit (folder) path id label type;
    devices = map
      (device: { deviceId = cfg.declarative.devices.${device}.id; })
      (filter (d: d != cfg.thisDevice) folder.devices);
    rescanIntervalS = folder.rescanInterval;
    fsWatcherEnabled = folder.watch;
    fsWatcherDelayS = folder.watchDelay;
    ignorePerms = folder.ignorePerms;
  }) (filterAttrs (
    _: folder:
    folder.enable && builtins.elem cfg.thisDevice folder.devices
  ) cfg.declarative.folders);

  # get the api key by parsing the config.xml
  getApiKey = pkgs.writers.writeDash "getAPIKey" ''
    ${pkgs.libxml2}/bin/xmllint \
      --xpath 'string(configuration/gui/apikey)'\
      ${cfg.configDir}/config.xml
  '';

  updateConfig = pkgs.writers.writeDash "merge-syncthing-config" ''
    set -efu
    # wait for syncthing port to open
    until ${pkgs.curl}/bin/curl -Ss ${cfg.guiAddress} -o /dev/null; do
      # home-manager needs the full path because there's no default PATH set
      ${pkgs.coreutils}/bin/sleep 1
    done

    API_KEY=$(${getApiKey})
    OLD_CFG=$(${pkgs.curl}/bin/curl -Ss \
      -H "X-API-Key: $API_KEY" \
      ${cfg.guiAddress}/rest/system/config)

    # generate the new config by merging with the nixos config options
    NEW_CFG=$(echo "$OLD_CFG" | ${pkgs.jq}/bin/jq -s '.[] as $in | $in * {
      "devices": (${builtins.toJSON devices}${optionalString (! cfg.declarative.overrideDevices) " + $in.devices"}),
      "folders": (${builtins.toJSON folders}${optionalString (! cfg.declarative.overrideFolders) " + $in.folders"})
    }')

    # POST the new config to syncthing
    echo "$NEW_CFG" | ${pkgs.curl}/bin/curl -Ss \
      -H "X-API-Key: $API_KEY" \
      ${cfg.guiAddress}/rest/system/config -d @-

    # restart syncthing after sending the new config
    ${pkgs.curl}/bin/curl -Ss \
      -H "X-API-Key: $API_KEY" \
      -X POST \
      ${cfg.guiAddress}/rest/system/restart
  '';
in
{
  ###### interface
  options = {
    services.syncthing = {
      enable = mkEnableOption "Syncthing continuous file synchronization";
      thisDevice = mkOption {
        type = with types; str;
        description = ''
          Name of the current syncthing device, so as to avoid adding itself as a peer.
        '';
      };
      declarative = {
        cert = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to users cert.pem file, will be copied into syncthing's
            <literal>configDir</literal>
          '';
        };

        key = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to users key.pem file, will be copied into syncthing's
            <literal>configDir</literal>
          '';
        };

        overrideDevices = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to delete the devices which are not configured via the
            <literal>declarative.devices</literal> option.
            If set to false, devices added via the webinterface will
            persist but will have to be deleted manually.
          '';
        };

        devices = mkOption {
          default = {};
          description = ''
            Peers/devices which syncthing should communicate with.
          '';
          example = {
            bigbox = {
              id = "7CFNTQM-IMTJBHJ-3UWRDIU-ZGQJFR6-VCXZ3NB-XUH3KZO-N52ITXR-LAIYUAU";
              addresses = [ "tcp://192.168.0.10:51820" ];
            };
          };
          type = types.attrsOf (types.submodule ({ config, ... }: {
            options = {

              name = mkOption {
                type = types.str;
                default = config._module.args.name;
                description = ''
                  Name of the device
                '';
              };

              addresses = mkOption {
                type = types.listOf types.str;
                default = [];
                description = ''
                  The addresses used to connect to the device.
                  If this is let empty, dynamic configuration is attempted
                '';
              };

              id = mkOption {
                type = types.str;
                description = ''
                  The id of the other peer, this is mandatory. It's documented at
                  https://docs.syncthing.net/dev/device-ids.html
                '';
              };

              introducer = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  If the device should act as an introducer and be allowed
                  to add folders on this computer.
                '';
              };

            };
          }));
        };

        overrideFolders = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to delete the folders which are not configured via the
            <literal>declarative.folders</literal> option.
            If set to false, folders added via the webinterface will persist
            but will have to be deleted manually.
          '';
        };

        folders = mkOption {
          default = {};
          description = ''
            folders which should be shared by syncthing.
          '';
          example = {
            "/home/user/sync" = {
              id = "syncme";
              devices = [ "bigbox" ];
            };
          };
          type = types.attrsOf (types.submodule ({ config, ... }: {
            options = {

              enable = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  share this folder.
                  This option is useful when you want to define all folders
                  in one place, but not every machine should share all folders.
                '';
              };

              path = mkOption {
                type = types.str;
                default = config._module.args.name;
                description = ''
                  The full path to the folder which should be shared.
                '';
              };

              id = mkOption {
                type = types.str;
                default = config._module.args.name;
                description = ''
                  The id of the folder. Must be the same on all devices.
                '';
              };

              label = mkOption {
                type = types.str;
                default = config._module.args.name;
                description = ''
                  The label of the folder.
                '';
              };

              devices = mkOption {
                type = types.listOf types.str;
                default = [];
                description = ''
                  The devices this folder should be shared with. Must be defined
                  in the <literal>declarative.devices</literal> attribute.
                '';
              };

              rescanInterval = mkOption {
                type = types.int;
                default = 3600;
                description = ''
                  How often the folders should be rescaned for changes.
                '';
              };

              type = mkOption {
                type = types.enum [ "sendreceive" "sendonly" "receiveonly" ];
                default = "sendreceive";
                description = ''
                  Whether to send only changes from this folder, only receive them
                  or propagate both.
                '';
              };

              watch = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether the folder should be watched for changes by inotify.
                '';
              };

              watchDelay = mkOption {
                type = types.int;
                default = 10;
                description = ''
                  The delay after an inotify event is triggered.
                '';
              };

              ignorePerms = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to propagate permission changes.
                '';
              };

            };
          }));
        };
      };
      guiAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:8384";
        description = ''
          Address to serve the GUI.
        '';
      };
      all_proxy = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "socks5://address.com:1234";
        description = ''
          Overwrites all_proxy environment variable for the syncthing process to
          the given value. This is normaly used to let relay client connect
          through SOCKS5 proxy server.
        '';
      };
      dataDir = mkOption {
        type = types.path;
        default = "~/sync";
        description = ''
          Path where synced directories will exist.
        '';
      };
      configDir = mkOption {
        type = types.path;
        description = ''
          Path where the settings and keys will exist.
        '';
        default = "${config.xdg.configHome}/syncthing";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.syncthing;
        defaultText = "pkgs.syncthing";
        example = literalExpression "pkgs.syncthing";
        description = ''
          Syncthing package to use.
        '';
      };
    };
  };

  config = mkIf config.services.syncthing.enable {
    home.packages = [
      cfg.package
    ];
    systemd.user.services = {
      syncthing = {
        Unit = {
          Description = "Syncthing - Open Source Continuous File Synchronization";
          Documentation = "man:syncthing(1)";
          After = [ "network.target" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = ''${pkgs.syncthing}/bin/syncthing \
            -no-browser \
            -gui-address=${cfg.guiAddress} \
            -logflags=0'';
          Restart = "on-failure";
          SuccessExitStatus = [ 2 3 4 ];
          RestartForceExitStatus = [ 3 4 ];
          ExecStartPre = mkIf (cfg.declarative.cert != null || cfg.declarative.key != null)
            "+${pkgs.writers.writeBash "syncthing-copy-keys" ''
              mkdir -p ${cfg.configDir}
              chown "$USER":$(id -gn) ${cfg.configDir}
              chmod 700 ${cfg.configDir}
              ${optionalString (cfg.declarative.cert != null) ''
                cp ${toString cfg.declarative.cert} ${cfg.configDir}/cert.pem
                chown "$USER":$(id -gn) ${cfg.configDir}/cert.pem
                chmod 400 ${cfg.configDir}/cert.pem
              ''}
              ${optionalString (cfg.declarative.key != null) ''
                cp ${toString cfg.declarative.key} ${cfg.configDir}/key.pem
                chown "$USER":$(id -gn) ${cfg.configDir}/key.pem
                chmod 400 ${cfg.configDir}/key.pem
              ''}
            ''}";
          Environment = [
            "STNORESTART=yes"
            "STNOUPGRADE=yes"
          ] ++ optional (cfg.all_proxy != null) "all_proxy=${cfg.all_proxy}";
        };
      };
      syncthing-init = mkIf (cfg.declarative.devices != {} || cfg.declarative.folders != {}) {
        Unit = {
          Description = "Syncthing - Declarative Config Initialisation/Merging";
          After = [ "syncthing.service" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          RemainAfterExit = true;
          Type = "oneshot";
          ExecStart = toString updateConfig;
        };
      };
    };
  };
}
