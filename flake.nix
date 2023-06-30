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

    # Additional NixOS/HM modules
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs"; # Only used by its checks attribute
    impermanence.url = github:nix-community/impermanence;
    nix-index-database.url = github:nix-community/nix-index-database;
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... } @ inputs: {
    nixosModules.default = { ... }: {
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.impermanence.nixosModules.impermanence
        inputs.nix-index-database.nixosModules.nix-index
        ./nixos/module.nix
      ];
    };
    homeModules.default = import ./home-manager/module.nix;
  };
}
