{ config, pkgs, lib, ... }:

with lib;

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = mkMerge [
  ];
}
