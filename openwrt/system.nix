# TODO hostname, include it in various produced filenames too
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    mkOption
    optionalAttrs
    singleton
    types
    ;
  inherit (config.lib) compileMoonBin writeUCIScript;
in
{
  # sshHostEd25519
  options = {
    rootHashedPassword = mkOption {
      type = with types; nullOr (passwdEntry str);
      default = null;
      description = ''
        Specifies the hashed password for the root user. We don't expose
        password configuration for other users, as OpenWRT systems are
        typically single-user in effect, due to their embedded nature.

        You can generate a new hashed password with `mkpasswd`, e.g.: `mkpasswd
        -m sha512crypt --rounds=20000`.
      '';
    };
    sshHostEd25519Key = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        Specifies an ed25519 key to use for the host key. Will be converted
        from OpenSSH to dropbear's format automatically. If not set, the
        image will generate an ed25519 host key on first boot.
      '';
    };
  };
  config =
    let
      defaultPasswordScript = writeUCIScript "90_set_root_password" ''
        #!/bin/sh
        # shellcheck disable=1091
        . /lib/functions/guard.sh

        guard "set_root_password"
        # shellcheck disable=2016
        /usr/bin/replace-root-password ${escapeShellArg config.rootHashedPassword}
      '';
      fixupScript = writeUCIScript "90_fixups" ''
        #!/bin/sh
        # shellcheck disable=1091
        . /lib/functions/guard.sh

        guard "fixups"
        chmod 0600 /etc/dropbear/*_host_key
      '';
    in
    {
      files = {
        "/etc/uci-defaults/${defaultPasswordScript.name}".source = defaultPasswordScript;
        "/etc/uci-defaults/${fixupScript.name}".source = fixupScript;
        "/usr/bin/replace-root-password".source =
          compileMoonBin "replace-root-password" ./replace-root-password.moon;
        "/usr/bin/replace-root-password".mode = "0755";
      }
      // optionalAttrs (config.sshHostEd25519Key != null) {
        "/etc/dropbear/dropbear_ed25519_host_key".source =
          pkgs.runCommandLocal "openwrt-ed25519-key"
            {
              nativeBuildInputs = [
                pkgs.dropbear
              ];
              src = config.sshHostEd25519Key;
            }
            ''
              dropbearconvert openssh dropbear "$src" "$out"
            '';
      };
    };
}
