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
  inherit (lib) attrValues concatMapStringsSep escapeShellArg hasPrefix mkIf mkOption types;
  # NOTE: This is *not* equivalent to nixpkgs.lib.isStorePath, because that
  # only returns true for top-level store paths, not files contained *within*
  # store paths.
  isInNixStore = pathlike: let
      pathStr = "${pathlike}";
    in builtins.substring 0 1 pathStr == "/" && hasPrefix builtins.storeDir pathStr;

  storePathType = (types.addCheck types.path (v: !builtins.isPath v && isInNixStore v)) // {
    description = "A *string* representation of a path contained within the Nix store";
  };

  secretsDir = "/etc/nixos/initrd-secrets";

  storeSecretType = types.submodule ({ config, ... }: {
    options = {
      source = mkOption {
        type = storePathType;
        description = ''
          Path or string coercible to path, for a file contained within the Nix store.
        '';
      };
      path = mkOption {
        type = types.path;
        description = ''
          The non-store path the file will be copied to during activation.
          Cannot be set manually, this attribute is used to reference the path
          that will be used.
        '';
        default = "${secretsDir}/${builtins.hashFile "sha256" config.source}";
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
  };

  config = mkIf (cfg.storeSecrets != {}) {
    system.activationScripts.initrdStoreSecrets = ''
      function populateInitrdStoreSecretsDir {
        echo "Ensuring initrd store-secrets directory is populated"
        local initrdSecretsDir=${escapeShellArg secretsDir}
        mkdir -p "$initrdSecretsDir"
        chmod 0700 "$initrdSecretsDir"
        local source
        local dest
    '' + (concatMapStringsSep "\n" ({source, path}: ''
        source="$(${pkgs.coreutils}/bin/realpath ${escapeShellArg source})"
        dest=${escapeShellArg path}
        if [[ ! -e "$dest" ]]; then
          cp -vf "$source" "$dest"
        else
          printf "%s already exists\n" "$dest"
        fi
    '') (attrValues cfg.storeSecrets)) + ''
      }
      populateInitrdStoreSecretsDir
    '';
  };
}
