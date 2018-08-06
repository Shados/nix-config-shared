{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    neovim-remote
    silver-searcher # `ag`
    universal-ctags
  ];
}
