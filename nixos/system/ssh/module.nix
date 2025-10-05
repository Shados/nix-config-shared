{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStrings
    concatMapStringsSep
    filterAttrs
    flip
    getAttr
    mkForce
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;
  inherit (config.lib.sn) indentLinesBy;
  cfg = config.services.openssh;
  cfgc = config.programs.ssh;

  globalHosts = map (h: getAttr h cfgc.globalHosts) (attrNames cfgc.globalHosts);
in
{
  options = {
    services.openssh = {
      enableMosh = mkOption {
        type = with types; bool;
        default = true;
        description = ''
          Whether or not to enable Mosh connectivity.
        '';
      };
    };
    programs.ssh = {
      globalHosts = mkOption {
        description = ''
          Global list of configured ssh_config Host entries, applied to each
          user. Can reference private keys in the Nix store.
        '';
        default = { };
        type = types.loaOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                name = mkOption {
                  type = types.str;
                  description = ''
                    The name of the ssh host. If undefined, the name of the
                    attribute set will be used.
                  '';
                  example = "shados.net";
                  default = name;
                };
                hostName = mkOption {
                  type = types.str;
                  description = ''
                    The hostname of the ssh host.
                  '';
                };
                user = mkOption {
                  type = types.nullOr types.str;
                  description = ''
                    The user to connect to the ssh host as.
                  '';
                  default = null;
                };
                port = mkOption {
                  type = types.nullOr types.int;
                  description = ''
                    The port of the ssh host, leave black to use ssh_config default.
                  '';
                  default = null;
                };
                keyFile = mkOption {
                  type = types.nullOr types.path;
                  description = ''
                    The path to the ssh key to use for this host, leave blank if
                    not using key-based authentication or if you want to specify
                    this on the command line, or via default key.
                  '';
                  default = null;
                };
                extraConfig = mkOption {
                  type = with types; nullOr lines;
                  default = null;
                  description = ''
                    Extra lines of ssh_config to be appended to this Host entry.
                  '';
                  example = "ProxyCommand openssl s_client -connect %h:%p -quiet 2>/dev/null";
                };
              };
            }
          )
        );
      };
      defaultPort = mkOption {
        description = ''
          Default port to attempt to connect to remote hosts on.
        '';
        default = 54201;
        type = types.int;
      };
    };
  };
  config = mkMerge [
    {
      programs.ssh.extraConfig = ''
        # Per-host matches
        ${flip concatMapStrings globalHosts (host: ''
          Host ${host.name}
            HostName ${host.hostName}
            ${optionalString (host.user != null) ''User ${toString host.user}''}
            ${optionalString (host.port != null) ''Port ${toString host.port}''}
            ${optionalString (host.keyFile != null) ''IdentityFile ${toString host.keyFile}''}
            ${optionalString (host.extraConfig != null) (indentLinesBy 2 (host.extraConfig))}
        '')}
        Match all
          Port ${toString cfgc.defaultPort}
      '';
    }
    (mkIf cfg.enableMosh {
      # Add Mosh & allow Mosh ports :)
      environment.systemPackages = [ pkgs.mosh ];
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 60000;
          to = 61000;
        }
      ];
    })
  ];
}
