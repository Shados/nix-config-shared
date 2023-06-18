{ config, lib, ... }:
let
  inherit (lib) filterAttrs mkIf;
  regularSecrets = filterAttrs (n: v: !v.neededForUsers) config.sops.secrets;
in
{
  # Ensure non-users-secrets from sops are only initialised *after*
  # impermanence's persistence module has linked files into place, otherwise we
  # likely do not have the decryption key (which is most-frequently the ssh
  # host key).
  config = mkIf (regularSecrets != {} && config.environment.persistence != {}) {
    system.activationScripts.setupSecrets.deps = [ "persist-files" ];
  };
}
