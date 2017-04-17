{ config, pkgs, ... }:

{
  imports = [
    ./nft-firewall.nix
    ./pppd.nix
    ./sn-firewall.nix
  ];
}
