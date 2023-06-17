{ config, lib, pkgs, ... }:
let
  inherit (lib) attrNames concatMapStrings flip getAttr mkIf mkMerge mkOption optionalString types;
  cfg = config.services.openssh;
  clcfg = config.programs.ssh;

  globalHosts = map (h: getAttr h clcfg.globalHosts) (attrNames clcfg.globalHosts);
in
{
  options = {
    services.openssh = {
      allowed_users = mkOption {
        description = ''
          A list of the users allowed to log in via SSH.
        '';
        default = [];
        type = types.nullOr (types.listOf types.str);
      };
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
          Global list of configured ssh_config Host entries, applied to each user. Can reference private keys in the Nix store.
        '';
        default = {};
        type = types.loaOf (types.submodule ({ name, ... }: {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                The name of the ssh host. If undefined, the name of the attribute set will be used.
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
                The path to the ssh key to use for this host, leave blank if not using key-based authentication or if you want to specify this on the command line, or via default key.
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
        }));
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
      services.openssh = {
        extraConfig = ''
          AllowUsers ${concatMapStrings (user: ''${user} '') cfg.allowed_users}
        '';
      };
      programs.ssh.extraConfig = ''
        # Per-host matches
        ${flip concatMapStrings globalHosts (host: ''
          Host ${host.name}
            HostName ${host.hostName}
            ${optionalString (host.user != null) ''User ${toString host.user}''}
            ${optionalString (host.port != null) ''Port ${toString host.port}''}
            ${optionalString (host.keyFile != null) ''IdentityFile ${toString host.keyFile}''}
            ${optionalString (host.extraConfig != null) host.extraConfig}
        '')}
        Match all
          Port ${toString clcfg.defaultPort}
      '';
    }
    (mkIf cfg.enableMosh {
      # Add Mosh & allow Mosh ports :)
      environment.systemPackages = [ pkgs.mosh ];
      networking.firewall.allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];
    })
  ];
}
