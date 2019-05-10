{ config, pkgs, ... }:

{
  disabledModules = [
    "services/networking/dnscrypt-proxy2.nix"
  ];
  imports = [
    ./dnscrypt2.nix
    ./nft-firewall.nix
    ./pppd.nix
    ./sn-firewall.nix
  ];
}
