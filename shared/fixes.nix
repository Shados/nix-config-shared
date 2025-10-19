final: prev:
let
  inherit (prev) lib;
  inherit (prev.lib) getVersion versionAtLeast;
in
{
  fop =
    if versionAtLeast (getVersion prev.fop) "2.10" then prev.fop else prev.callPackage ./fop.nix { };

  # FIXME: Remove once nixpkgs #177733 is resolved
  borgbackup = prev.borgbackup.overrideAttrs (finalAttrs: {
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

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      # Fix for uncaught issue in PR #341434
      pastedeploy = pyprev.pastedeploy.overridePythonAttrs (oa: {
        src =
          with oa;
          prev.fetchFromGitHub {
            owner = "Pylons";
            repo = pname;
            rev = "refs/tags/${version}";
            hash = "sha256-yR7UxAeF0fQrbU7tl29GpPeEAc4YcxHdNQWMD67pP3g=";
          };
      });
    })
  ];

  # Bump gamescope to get fix for gamescope issue #1900
  gamescope =
    if versionAtLeast (getVersion prev.gamescope) "3.16.15" then
      prev.gamescope
    else
      prev.gamescope.overrideAttrs (oa: rec {
        version = "3.16.15";
        src = prev.fetchFromGitHub {
          owner = "ValveSoftware";
          repo = "gamescope";
          tag = version;
          fetchSubmodules = true;
          hash = "sha256-/JMk1ZzcVDdgvTYC+HQL09CiFDmQYWcu6/uDNgYDfdM=";
        };
      });
}
