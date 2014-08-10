{ config, pkgs, ... }:

{
  imports = [
    ./hah.nix
    ./sn-firewall.nix
  ];
}
