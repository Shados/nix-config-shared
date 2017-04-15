{ config, pkgs, ... }:

{
  imports = [
    ./pppd.nix
    ./nft-firewall.nix
    ./sn-firewall.nix
  ];
}
