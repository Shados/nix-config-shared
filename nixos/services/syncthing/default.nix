{ config, lib, pkgs, ... }:
with lib;
{
  disabledModules = [
    "services/networking/syncthing.nix"
  ];
  imports = [
    ./module.nix
    ./data.nix
  ];
}
