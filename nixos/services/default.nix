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
    ./teamspeak3.nix
    ./wireguard.nix
  ];
}
