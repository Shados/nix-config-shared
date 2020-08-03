# Service configuration
{ config, pkgs, ... }:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
    ./quassel.nix
    ./samba.nix
    ./syncthing
    ./teamspeak3.nix
    ./wireguard.nix
  ];
}
