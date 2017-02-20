{ config, pkgs, ... }:

{
  imports = [
    ./pppd.nix
    ./sn-firewall.nix
  ];
}
