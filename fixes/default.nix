{ config, pkgs, lib, ... }:

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = lib.mkMerge [
    # 2018-03-21: recent versions of deoplete need python-neovim >= 0.2.4
    # TODO remove after commmit 366c79e17f212e581d16a17ca67eb186fd005c61 is in channel
    {
      nixpkgs.config.packageOverrides = let
        python_override = localpython: localpython.override {
          packageOverrides = self: super: {
            neovim = super.neovim.overrideAttrs (oldAttrs: rec {
              pname = "neovim";
              version = "0.2.4";
              src = super.fetchPypi {
                inherit pname version;
                sha256 = "0accfgyvihs08bwapgakx6w93p4vbrq2448n2z6gw88m2hja9jm3";
              };
            });
          };
        };
        fixedWrapNeovim = pkgs.wrapNeovim.override {
          pythonPackages = (python_override pkgs.python2).pkgs;
          python3Packages = (python_override pkgs.python3).pkgs;
        };
      in pkgs: with pkgs.lib; {
        neovim = if (versionOlder (getVersion pkgs.pythonPackages.neovim) "0.2.4") then
          fixedWrapNeovim pkgs.neovim-unwrapped { }
        else
          pkgs.neovim;
      };
    }
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
      # Get cython working with python 3.7
      nixpkgs.overlays = [(self: super: {
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
          cython = if (super.lib.versionOlder (super.lib.getVersion pysuper.cython) "0.28.5")
            then fixedCython
            else pysuper.cython;
        }) super.pythonOverrides;
      })];
    }
  ];
}
