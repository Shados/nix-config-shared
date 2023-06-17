{ config, inputs, lib, pkgs, system, ... }:
{
  imports = [
    ./apps
    ./fixes
    ./pkgs
    ./programs
    ./system
    ./services

    # Library functions
    ./lib
  ];

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
  in lib.mkMerge [
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; lib.mkBefore [
        lua-overrides
        python-overrides
      ];
    }
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; [
        lua-packages
        python-packages
        fixes
        oldflash # FIXME: remove
        dochelpers
      ];
    }
    {
      nixpkgs.overlays = [
        inputs.nur.overlay
      ];
    }
  ];
}
