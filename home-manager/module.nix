{ config, inputs, lib, pkgs, system, ... }:
{
  imports = [
    ./apps
    ./fixes
    ./pkgs
    ./programs
    ./system
    ./services
  ];
}
