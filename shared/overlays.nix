{ inputs, lib, system, ... }:
let
  inherit (lib) mkBefore mkMerge singleton;
in
{
  config = let
    # shados-nur-src = /home/shados/technotheca/artifacts/media/software/nix/nur-packages;
    # shados-nur-no-packages = import shados-nur-src { };
    # shados-nur = import shados-nur-src { inherit pkgs; };
    # base-nur-no-packages = import inputs.nur {
    #   nurpkgs = inputs.nixpkgs.legacyPackages.${system};
    #   pkgs = null;
    # };
  # in let
    # nur-no-packages = base-nur-no-packages // { repos = base-nur-no-packages.repos // { shados = shados-nur-no-packages; }; };
    nur-no-packages = import inputs.nur {
      nurpkgs = inputs.nixpkgs.legacyPackages.${system};
      pkgs = null;
    };
  in mkMerge [
    { nixpkgs.overlays = [
        (self: super: rec {
          # Could cause some breakage, but personally I pretty much always want
          # the 5.2 compat features
          luajit = super.luajit.override(oa: {
            enable52Compat = true;
            # TODO upstream a passthruFun splicing fix into nixpkgs?
            passthruFun = {self, ...}@inputs: oa.passthruFun (inputs // { self = luajit; });
          });

          fio-plot = super.callPackage (
            {
              lib,
              python3Packages,
              fetchFromGitHub,
              coreutils,
              fio,
            }:
            let
              inherit (python3Packages) buildPythonApplication numpy pillow pyparsing matplotlib rich setuptools;
            in
            buildPythonApplication rec {
              pname = "fio-plot";
              version = "1.1.16";

              src = fetchFromGitHub {
                owner = "louwrentius"; repo = "fio-plot";
                rev = "v${version}";
                sha256 = "sha256-yN0gVm6ZYEIoh91d+0ohJ9yU+VWwYEq3MoG+WgBrs2Q=";
              };

              postPatch = ''
                substituteInPlace setup.py \
                  --replace '"pyan3", ' "" \
                  --replace 'scripts=["bin/fio-plot", "bin/bench-fio"],' ""
                rm -rf bin
              '';

              propagatedBuildInputs = [
                numpy pillow pyparsing matplotlib rich
                setuptools # for pkg_resources
                # pyan3 # only used for internal docs
              ];

              propagatedUserEnvPkgs = [
                coreutils fio
              ];

              meta = with lib; {
                description = "Create charts from FIO storage benchmark tool output";
                homepage = "https://github.com/louwrentius/fio-plot";
                license = licenses.bsd3;
                platforms = platforms.linux;
              };
            }
          ) { };
        })
        # Setup access to the Nix User Repository
        inputs.nur.overlays.default
      ];
    }
    # Pull in overlays from my NUR
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; mkBefore [
        lua-overrides
      ];
    }
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; [
        lua-packages
        python-packages
        fixes
        oldflash
        dochelpers
        (import ./fixes.nix)
      ];
    }
  ];
}
