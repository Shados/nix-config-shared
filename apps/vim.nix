{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    silver-searcher # `ag`
    universal-ctags
  ];
  nixpkgs.config.packageOverrides = pkgs: with pkgs; {
      # Work around regression introduced by
      # ba58b425f10854cc4d7fb2dce9fbb79d09f882e8 2018-02-22
      # TODO remove this later
      neovim = pkgs.neovim.override {
        withRuby = false;
      };
  };
}
