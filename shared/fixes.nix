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

  makemkv = prev.makemkv.overrideAttrs(oa: {
    prePatch = oa.prePatch or "" + ''
      sed -i Makefile.in \
        -e 's/ldconfig/true/g'
    '';
    installFlags = oa.installFlags or [] ++ [ "DESTDIR=" "PREFIX=$(out)" ];
    installPhase = ''
      runHook preInstall

      local flagsArray=(
          ''${enableParallelInstalling:+-j''${NIX_BUILD_CORES}}
          SHELL="$SHELL"
      )

      concatTo flagsArray makeFlags makeFlagsArray installFlags installFlagsArray installTargets=install

      echoCmd 'install flags' "''${flagsArray[@]}"

      pushd ../makemkv-oss-"$version"
      make ''${makefile:+-f $makefile} "''${flagsArray[@]}"
      popd
      pushd ../makemkv-bin-"$version"
      mkdir tmp
      echo accepted > tmp/eula_accepted
      make ''${makefile:+-f $makefile} "''${flagsArray[@]}"
      popd

      unset flagsArray

      runHook postInstall
    '';
  });
}
