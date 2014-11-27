{ config, pkgs, ... }:

with pkgs.lib;

let

  cfg = config.services.openssh;
  clcfg = config.programs.ssh;

  sshHostOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the ssh host. If undefined, the name of the attribute set will be used.
        '';
        example = "shados.net";
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
    };
    config = {
      name = mkDefault name;
    };
  };


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
    };
    programs.ssh = {
      globalHosts = mkOption {
        description = ''
          Global list of configured ssh_config Host entries, applied to each user. Can reference private keys in the Nix store.
        '';
        default = {};
        type = types.loaOf types.optionSet;
        options = [ sshHostOpts ];
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

  config = {
    services.openssh = {
      enable = true;
      # Some options for improved security
      ports = [ 54201 ]; # Non-default port for security, SSH module automatically adds its ports to the FW
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      permitRootLogin = "no";
      extraConfig = 
        ''
          AllowUsers ${concatMapStrings (user: ''${user} '') cfg.allowed_users}
        '';
    };

    # Add Mosh & allow Mosh ports :)
    environment.systemPackages = [ pkgs.mosh ];
    networking.firewall.allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];

    programs.ssh.extraConfig = ''
      Match all
        Port ${toString clcfg.defaultPort}
      ${flip concatMapStrings globalHosts (host: ''
        Host ${host.name}
          HostName ${host.hostName}
          ${optionalString (host.user != null) ''User ${toString host.user}''}
          ${optionalString (host.port != null) ''Port ${toString host.port}''}
          ${optionalString (host.keyFile != null) ''IdentityFile ${pkgs.writeText ''ssh-private-key-${host.name}'' (readFile host.keyFile)}''}
      '')}
    '';
  };
}
