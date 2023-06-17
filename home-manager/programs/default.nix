{ config, lib, pkgs, ... }:
{
  imports = [
    ./chromium.nix
    ./eww.nix
    ./flake8.nix
    ./nnn.nix
    ./pqiv.nix
    ./yabridge.nix
  ];
}
