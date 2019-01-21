{ config, pkgs, lib, ... }:

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = lib.mkMerge [
    # Workaround for https://github.com/NixOS/nixpkgs/issues/44426 python
    # overrides not being composable...
    {
      nixpkgs.overlays = lib.mkBefore [
        (self: super: let
            pyNames = [
              "python27" "python35" "python36" "python37"
              "pypy"
            ];
            overriddenPython = name: [
              { inherit name; value = super.${name}.override { packageOverrides = self.pythonOverrides; }; }
              { name = "${name}Packages"; value = super.recurseIntoAttrs self.${name}.pkgs; }
            ];
            overriddenPythons = builtins.concatLists (map overriddenPython pyNames);
          in {
            pythonOverrides = pyself: pysuper: {};
            sn = (super.sn or { }) // {
              # The below is a straight wrapper for clarity of intent, use like:
              # pythonOverrides = buildPythonOverrides (pyself: pysuper: { ... # overrides }) super.pythonOverrides;
              buildPythonOverrides = newOverrides: currentOverrides: super.lib.composeExtensions newOverrides currentOverrides;
            };
          } // builtins.listToAttrs overriddenPythons
        )
      ];
    }
    {
      nixpkgs.overlays = [(self: super: with super.lib; {
        # Get cython working with python 3.7
        pythonOverrides = super.sn.buildPythonOverrides (pyself: pysuper: let
          fixedCython = pysuper.cython.overrideAttrs(oldAttrs: rec {
            inherit (oldAttrs) pname;
            name = "${pname}-${version}";
            version = "0.28.5";

            src = pysuper.fetchPypi {
              inherit pname version;
              sha256 = "b64575241f64f6ec005a4d4137339fb0ba5e156e826db2fdb5f458060d9979e0";
            };

            patches = [
              (super.fetchpatch {
                name = "Cython-fix-test-py3.7.patch";
                url = https://github.com/cython/cython/commit/eae37760bfbe19e7469aa41269480b84ce12b6cd.patch;
                sha256 = "0irk53psrs05kzzlvbfv7s3q02x5lsnk5qrv0zd1ra3mw2sfyym6";
              })
            ];
          });
        in {
          cython = if (versionOlder (getVersion pysuper.cython) "0.28.5")
            then fixedCython
            else pysuper.cython;
        }) super.pythonOverrides;
        # Patch spurious O_TMPFILE logging in older xorg
        xorg = super.xorg // {
          xorgserver = let
            fixedXorgserver = super.xorg.xorgserver.overrideAttrs(oldAttrs: {
              patches = oldAttrs.patches or [] ++ [
                ./xorg-tmpfile.patch
              ];
            });
          in if (versionOlder (getVersion super.xorg.xorgserver) "1.20")
            then fixedXorgserver
            else super.xorg.xorgserver;
        };
        # Use mosh newer than 1.3.2 to get proper truecolor support
        mosh = if versionAtLeast (getVersion super.mosh) "1.3.3"
          then super.mosh
          else super.mosh.overrideAttrs (oldAttrs: rec {
              name = "${pname}-${version}";
              pname = "mosh";
              version = "unstable-2018-08-30";
              src = super.fetchFromGitHub {
                owner = "mobile-shell"; repo = pname;
                rev = "944fd6c796338235c4f3d8daf4959ff658f12760";
                sha256 = "0fwrdqizwnn0kmf8bvlz334va526mlbm1kas9fif0jmvl1q11ayv";
              };
            });
      })];
    }
  ];
}
