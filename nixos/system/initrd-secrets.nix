# TODO: migrate some stuff to lib
# NOTE: Only works properly if system is activated *before* bootloader
# installation is done. In other words: don't run `switch`, run `test` then
# `boot`.
# Content-addressed paths for the secrets ensures new/updated initrd secret
# files won't override old ones. Don't have a good way to garbage-collected
# old, unused secrets, but oh well. Unlikely to be necessary given I currently
# only use this for initrd SSH host keys, and the upstream issue should
# hopefully be fixed at some point...
# FIXME: Scrap this once nixpkgs issue #98100 is resolved
{ config, lib, pkgs, ... }:
let
  cfg = config.boot.initrd;
  inherit (lib) attrValues concatMapStringsSep escapeShellArg hasPrefix mkIf mkOption optional types;
  # NOTE: This is *not* equivalent to nixpkgs.lib.isStorePath, because that
  # only returns true for top-level store paths, not files contained *within*
  # store paths.
  isInNixStore = pathlike: let
      pathStr = "${pathlike}";
    in builtins.substring 0 1 pathStr == "/" && hasPrefix builtins.storeDir pathStr;

  storePathType = (types.addCheck types.path (v: !builtins.isPath v && isInNixStore v)) // {
    description = "A *string* representation of a path contained within the Nix store";
  };

  sopsSecretType = (types.addCheck types.path (v: hasPrefix "/run/secrets" v)) // {
    description = "A sops-nix secret path";
  };

  sha256HashType = (types.addCheck types.str (v: builtins.match "[[:xdigit:]]{64}" v != null)) // {
    description = "A base-16 representation of a sha256 hash";
  };

  storeSecretType = types.submodule ({ config, ... }: {
    options = {
      source = mkOption {
        type = types.either sopsSecretType storePathType;
        description = ''
          Path or string coercible to path, for a file contained within the Nix
          store, or for a sops-nix secret file.
        '';
      };
      hash = mkOption {
        type = sha256HashType;
        description = ''
          The sha256 hash of the source file. Will be calculated on the fly if
          the source is a Nix store path, otherwise must be supplied manually.

          Can be calculated using `sha256sum`.
        '';
        default = if storePathType.check config.source
          then builtins.hashFile "sha256" config.source
          else null;
      };
      path = mkOption {
        type = types.path;
        description = ''
          The non-store path the file will be copied to during activation.
          Cannot be set manually, this attribute is used to reference the path
          that will be used.
        '';
        default = "${cfg.secretsDir}/${config.hash}";
        readOnly = true;
      };
    };
  });
in
{
  options = {
    boot.initrd.storeSecrets = mkOption {
      type = types.attrsOf storeSecretType;
      default = {};
    };
    boot.initrd.secretsDir = mkOption {
      type = types.path;
      default = "/etc/nixos/initrd-secrets";

      description = ''
        The path to store initrd secrets in, where they will be copied into
        the initrd from on every rebuild of the initrd-secrets files..
      '';
    };
  };

  config = mkIf (cfg.storeSecrets != {}) {
    system.activationScripts.initrdStoreSecrets.text = ''
      function populateInitrdStoreSecretsDir {
        echo "Ensuring initrd store-secrets directory is populated"
        local initrdSecretsDir=${escapeShellArg cfg.secretsDir}
        mkdir -p "$initrdSecretsDir"
        chmod 0700 "$initrdSecretsDir"
        local source
        local dest
    '' + (concatMapStringsSep "\n" ({source, path, hash}: ''
        source="$(${pkgs.coreutils}/bin/realpath ${escapeShellArg source})"
        dest=${escapeShellArg path}
        if [[ ! -e "$dest" ]]; then
          local hash=$(sha256sum "$source" | cut -c -64)
          if [[ $hash != ${hash} ]]; then
            printf "Calculated hash of secret source file '%s' does not equal the supplied hash!\n\t%s != %s\n" "$source" "$hash" "${hash}"
            exit 1
          fi
          cp -vf "$source" "$dest"
        else
          printf "%s already exists\n" "$dest"
        fi
    '') (attrValues cfg.storeSecrets)) + ''
      }
      populateInitrdStoreSecretsDir
    '';
    system.activationScripts.initrdStoreSecrets.deps = []
      ++ optional (config.system.activationScripts ? setupSecrets) "setupSecrets"
      ;
  };
}
