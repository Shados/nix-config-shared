{ config, pkgs, ... }:

{
  imports = [
    ./pkgs
    ./services
  ];
}
