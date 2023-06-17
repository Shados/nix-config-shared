{ config, lib, pkgs, ... }:
with lib;
{
  lib = {
    sn = {
      baseUserPath = [
        "/run/wrappers/bin"
        "${config.home.profileDirectory}/bin"
        # Theoretically, this should be identical to the above, sans a symlink?
        "/etc/profiles/per-user/${config.home.username}/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/sbin"
        "/run/current-system/sw/bin"
      ];
      makePath = concatStringsSep ":";
      mkPoetryApplication = import ./poetry2nix.nix {
        inherit lib;
        inherit (pkgs.poetry2nix) mkPoetryApplication;
      };
    };
  };
}
