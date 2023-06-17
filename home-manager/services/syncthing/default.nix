{ config, lib, pkgs, inputs, ... }:
with lib;
{
  disabledModules = [ "services/syncthing.nix" ];
  imports = [
    ./module.nix
    # TODO replace once using flakes?
    ../../../nixos/services/syncthing/data.nix
  ];
}
