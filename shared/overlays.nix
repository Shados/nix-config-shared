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
    # Setup access to the Nix User Repository
    { nixpkgs.overlays = singleton inputs.nur.overlay;
    }
    # Pull in overlays from my NUR
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; mkBefore [
        lua-overrides
        python-overrides
      ];
    }
    { nixpkgs.overlays = with nur-no-packages.repos.shados.overlays; [
        lua-packages
        python-packages
        fixes
        oldflash
        dochelpers
      ];
    }
  ];
}
