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
        # FIXME: Remove once nixpkgs #177733 is resolved
        borgbackup = prev.borgbackup.overrideAttrs(finalAttrs: {
          postInstall = finalAttrs.postInstall or "" + ''
            mv $out/bin/borg $out/bin/.borg-real
            echo '#!${prev.stdenv.shell}' > "$out/bin/borg"

            cat << EOF >> "$out/bin/borg"
            realBorg="$out/bin/.borg-real"

            function borg(){
              local returnCode=0
              "\$realBorg" "\$@" || returnCode=\$?

              if [[ \$returnCode -eq 1 ]]; then
                return 0
              else
                return \$returnCode
              fi
            }

            borg "\$@"
            EOF

            chmod +x "$out/bin/borg"
          '';
        });
      });
    }
    (mkIf config.services.mullvad-vpn.enable {
      systemd.services.mullvad-daemon.environment.TALPID_NET_CLS_MOUNT_DIR = "/run/mullvad-net-cls-v1";
      systemd.services.mullvad-early-boot-blocking = rec {
        description = "Mullvad early boot network blocker";
        unitConfig.DefaultDependencies = "no";
        wants = [ "network-pre.target" ];
        wantedBy = [ "mullvad-daemon.service" ];
        before = wants ++ wantedBy;
        serviceConfig = {
          ExecStart = "${lib.getExe' config.services.mullvad-vpn.package "mullvad-daemon"} --initialize-early-boot-firewall";
          Type = "oneshot";
        };
      };
    })
  ];
}
