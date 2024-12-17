{
  description = "Shados' cross-machine shared configuration, defaults, modules, and packages not suitable for upstreaming or NUR";

  inputs = {
    # NOTE: This repo expects that the flake inputs end up available to NixOS
    # modules as a top-level 'inputs' argument along with config, pkgs, etc.
    #
    # FIXME: Figure out an ergonomic way to feed those in as part of this
    # flake? _module.args is not viable here, further thought required.
    #
    # TODO: Consider which dependencies should be in Niv pins vs. Flake inputs.
    # The major advantage of Flake inputs is that they can be overridden by
    # downstream consumers. They do have some disadvantages in terms of
    # evaluation performance due to Flake lock files not being re-used
    # currently (see Nix issues #6626 and #7730).

    # Baseline inputs
    nixpkgs.url = github:Shados/nixpkgs/local;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = github:nix-community/NUR;
    nur.inputs.nixpkgs.follows = "nixpkgs";

    # Additional NixOS/HM modules
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = github:nix-community/impermanence;
    nix-index-database.url = github:nix-community/nix-index-database;
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = github:fufexan/nix-gaming;
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";

    # Additional nixpkgs overlays
    neovim-nightly-overlay.url = github:nix-community/neovim-nightly-overlay;
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... } @ inputs: {
    nixosModules.default = { ... }: {
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.impermanence.nixosModules.impermanence
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nix-gaming.nixosModules.pipewireLowLatency
        ./nixos/module.nix
        ./shared/overlays.nix
        ./shared/lib.nix
        {
          nix.settings = {
            substituters = [
              "https://nix-community.cachix.org/"
            ];
            trusted-public-keys = [
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
          };
        }
      ];
    };
    homeModules.default = { ... }: {
      imports = [
        ./home-manager/module.nix
        ./shared/overlays.nix
        ./shared/lib.nix
      ];
    };
    openWRTModules.default = { ... }: {
      imports = [
        # ./openwrt/default.nix
        ./openwrt/modules.nix
      ];
    };
  };
}
