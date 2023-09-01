{ config, lib, pkgs, inputs, ... }:
with lib;
{
  disabledModules = [ "services/syncthing.nix" ];
  imports = [
    ./module.nix
  ];
}
