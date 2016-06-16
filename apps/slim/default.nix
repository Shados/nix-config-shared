{ config, pkgs, ... }:

{
  services.xserver.displayManager.slim = {
    theme = ./shadosnet-nixos-slim-theme.tar.gz;
  };
}
