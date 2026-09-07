# Service configuration
{ config, pkgs, ... }:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
    ./quassel.nix
    ./router
    ./samba.nix
    ./sops.nix
    ./syncthing
    ./wireguard.nix
  ];
}
