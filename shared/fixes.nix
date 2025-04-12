final: prev: let
  inherit (prev) lib;
  inherit (prev.lib) getVersion versionAtLeast;
in {
  # Backport sd-switch for RefuseManualStart/Stop fix
  sd-switch = let
    version = "0.5.3";
    src = prev.fetchFromSourcehut {
      owner = "~rycee";
      repo = "sd-switch";
      rev = version;
      hash = "sha256-9aIu37mmf4ZnmZZrU0GA6z+bHKwtfkA5KnLRLY0c2r8=";
    };
  in if versionAtLeast (getVersion prev.sd-switch) version then prev.sd-switch else
    (prev.sd-switch.overrideAttrs(finalAttrs: prevArgs: {
      inherit src version;
    })).override(prevArgs: rec {
      rustPlatform = prevArgs.rustPlatform // {
        buildRustPackage = args: prevArgs.rustPlatform.buildRustPackage (args // {
          name = "sd-switch-${version}";
          inherit src;
          cargoHash = "sha256-3XolxgnTIySucopogAzgf13IUCguJE6W17q506tUF6U=";
        });
      };
    });

  fop = if versionAtLeast (getVersion prev.fop) "2.10" then prev.fop else prev.callPackage ./fop.nix { };

  # Workaround for electron issue #43819
  electron = if versionAtLeast (getVersion prev.electron) "33.3.1" then prev.electron else
    prev.electron.override(origElectronArgs: {
      electron-unwrapped = origElectronArgs.electron-unwrapped.overrideAttrs(finalAttrs: prevAttrs: {
        patches = prevAttrs.patches or [] ++ [
          (prev.fetchpatch {
            url = "file://${./electron-33-portal-fix.patch}";
            sha256 = "sha256-+qEfbQkILgQX/Prz9qH7Td7eqsYcwUevKCX1Ezbln1U=";
          })
        ];
      });
    });

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
} // (let
  # FIXME: Remove once nixpkgs issue #375460 is resolved
  pinnedWine = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/da466ad.tar.gz";
    sha256 = "04wc7l07f34aml0f75479rlgj85b7n7wy2mky1j8xyhadc2xjhv5";
  }) {
    system = prev.system;
  };
in {
  yabridge = prev.yabridge.override {
    wine = pinnedWine.wineWowPackages.staging;
  };

  yabridgectl = prev.yabridgectl.override {
    wine = pinnedWine.wineWowPackages.staging;
  };
})
