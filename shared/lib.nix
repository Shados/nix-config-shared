{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep splitString;
in
{
  lib = {
    # `fileSystems` & related definition helpers
    fs = rec {
      pristineSnapshot = "blank";

      dsToFs = ds: {
        device = ds;
        fsType = "zfs";
        options = [ "zfsutil" ];
      };
      dsToBootFs =
        ds:
        (dsToFs ds)
        // {
          neededForBoot = true;
        };
    };
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
      mkPoetryApplication =
        let
          poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
        in
        import ./poetry2nix.nix {
          inherit lib;
          inherit (poetry2nix) mkPoetryApplication;
        };
      indentLinesBy =
        indentLevel: str:
        let
          indentStr = lib.strings.replicate indentLevel " ";
        in
        concatStringsSep "\n${indentStr}" (splitString "\n" (lib.strings.trim str));
    };
  };
}
