{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    silver-searcher # `ag`
  ];
}
