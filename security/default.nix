# Security-focused modules
{ config, pkgs, ... }:

{
  imports = [
    ./firewall.nix
  ];
}
