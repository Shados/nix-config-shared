{
  description = "Shados' cross-machine shared configuration, defaults, modules, and packages not suitable for upstreaming or NUR";

  inputs = {
    # NOTE: This repo expects that the flake inputs end up available to NixOS
    # modules as a top-level 'inputs' argument along with config, pkgs, etc.
    #
    # TODO: Add inputs, locked against a set of versions that:
    # 1) Are all from the same date (or nearest older date)
    # 2) Represents the "earliest compatible set of sources"
    # I'll also need a way of doing some very basic automated testing of bare
    # NixOS and HM configurations built from *just* this repo, in order to
    # confirm that the second point is met.
    #
    # Expected inputs:
    # - nixpkgs
    # - NUR: https://github.com/nix-community/NUR
    #
    # Can get away with not actually adding them currently because our only
    # output is a module function, and all input references within it go through a
    # top-level 'inputs' argument.
    #
    # TODO: Consider which dependencies should be in Niv pins vs. Flake inputs.
    # The major advantage of Flake inputs is that they can be overridden by
    # downstream consumers. They do have some disadvantages in terms of
    # evaluation performance due to Flake lock files not being re-used
    # currently (see Nix issues #6626 and #7730).
  };

  outputs = { self, ... } @ inputs: {
    nixosModules.default = import ./module.nix;
  };
}
