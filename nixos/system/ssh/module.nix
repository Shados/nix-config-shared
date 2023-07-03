{ config, lib, pkgs, ... }:
let
  inherit (lib) attrNames concatMapStrings concatStringsSep filterAttrs flip getAttr mkForce mkIf mkMerge mkOption optionalString types;
  cfg = config.services.openssh;
  cfgc = config.programs.ssh;

  globalHosts = map (h: getAttr h cfgc.globalHosts) (attrNames cfgc.globalHosts);

  # FIXME: Remove once nixpkgs PR 227442 is merged {{{
  # The splicing information needed for nativeBuildInputs isn't available
  # on the derivations likely to be used as `cfgc.package`.
  # This middle-ground solution ensures *an* sshd can do their basic validation
  # on the configuration.
  validationPackage = if pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform
    then cfgc.package
    else pkgs.buildPackages.openssh;

  # reports boolean as yes / no
  mkValueStringSshd = with lib; v:
        if isInt           v then toString v
        else if isString   v then v
        else if true  ==   v then "yes"
        else if false ==   v then "no"
        else if isList     v then concatStringsSep "," v
        else throw "unsupported type ${builtins.typeOf v}: ${(lib.generators.toPretty {}) v}";
  # dont use the "=" operator
  settingsFormat = (pkgs.formats.keyValue {
      mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = mkValueStringSshd;
    } " ";});
  configFile = settingsFormat.generate "config" (filterAttrs (n: v: v != null) cfg.settings);
  sshconf = pkgs.runCommand "sshd.conf-validated" { nativeBuildInputs = [ validationPackage ]; } ''
    cat ${configFile} - >$out <<EOL
    ${cfg.extraConfig}
    EOL

    ssh-keygen -q -f mock-hostkey -N ""
    sshd -t -f $out -h mock-hostkey
  '';
  # }}}
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
      # FIXME: Remove once nixpkgs PR 227442 is merged {{{
      settings = mkOption {
        type = types.submodule {
          options = {
            AllowUsers = mkOption {
              type = with types; nullOr (listOf str);
              apply = v: if v == null then v else concatStringsSep " " v;
              default = null;
              description = lib.mdDoc ''
                If specified, login is allowed only for the listed users.
                See {manpage}`sshd_config(5)` for details.
              '';
            };
            DenyUsers = mkOption {
              type = with types; nullOr (listOf str);
              apply = v: if v == null then v else concatStringsSep " " v;
              default = null;
              description = lib.mdDoc ''
                If specified, login is denied for all listed users. Takes
                precedence over [](#opt-services.openssh.settings.AllowUsers).
                See {manpage}`sshd_config(5)` for details.
              '';
            };
            AllowGroups = mkOption {
              type = with types; nullOr (listOf str);
              apply = v: if v == null then v else concatStringsSep " " v;
              default = null;
              description = lib.mdDoc ''
                If specified, login is allowed only for users part of the
                listed groups.
                See {manpage}`sshd_config(5)` for details.
              '';
            };
            DenyGroups = mkOption {
              type = with types; nullOr (listOf str);
              apply = v: if v == null then v else concatStringsSep " " v;
              default = null;
              description = lib.mdDoc ''
                If specified, login is denied for all users part of the listed
                groups. Takes precedence over
                [](#opt-services.openssh.settings.AllowGroups). See
                {manpage}`sshd_config(5)` for details.
              '';
            };
          };
        };
      };
      # }}}
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
    # FIXME: Remove once nixpkgs PR 227442 is merged {{{
    {
      environment.etc."ssh/sshd_config".source = mkForce sshconf;
    }
    # }}}
    {
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
          Port ${toString cfgc.defaultPort}
      '';
    }
    (mkIf cfg.enableMosh {
      # Add Mosh & allow Mosh ports :)
      environment.systemPackages = [ pkgs.mosh ];
      networking.firewall.allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];
    })
  ];
}
