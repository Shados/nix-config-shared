{ config, pkgs, ... }:

{
  disabledModules = [
    "services/networking/dnscrypt-proxy2.nix"
  ];
  imports = [
    ./dnscrypt2.nix
    ./pppd.nix
    ./sn-firewall.nix
  ];
}
