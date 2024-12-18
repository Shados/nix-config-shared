{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge singleton;
in
{
  config = mkMerge [
    {
      nixpkgs.overlays = singleton (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            # Fix for uncaught issue in PR #341434
            pastedeploy = pyprev.pastedeploy.overridePythonAttrs(oa: {
              src = with oa; prev.fetchFromGitHub {
                owner = "Pylons";
                repo = pname;
                rev = "refs/tags/${version}";
                hash = "sha256-yR7UxAeF0fQrbU7tl29GpPeEAc4YcxHdNQWMD67pP3g=";
              };
            });
          })
        ];
        # old version's source is missing
        checkbashisms = (prev.checkbashisms.override (oa: {
          fetchurl = args: lib.makeOverridable oa.fetchurl args;
        })).overrideAttrs(finalAttrs: prevAttrs: {
          version = "2.24.7";
          src = prevAttrs.src.override {
            hash = "sha256-iYQSqT2tG4DjdVDme3b2TErbSxkQqmELO22eq2Gmo4s=";
          };
        });
      });
    }
    (mkIf config.services.mullvad-vpn.enable {
      systemd.services.mullvad-daemon.environment.TALPID_NET_CLS_MOUNT_DIR = "/run/mullvad-net-cls-v1";
    })
  ];
}
