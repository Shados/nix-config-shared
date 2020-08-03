# Service configuration
{ config, pkgs, ... }:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
    ./quassel.nix
    ./samba.nix
    ./syncthing.nix
    ./teamspeak3.nix
    ./wireguard.nix
  ];
}
