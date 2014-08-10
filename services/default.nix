# Service configuration
{ config, pkgs, ... }:

{
  imports = [
    ./nginx.nix
    ./postgresql.nix
    ./quassel.nix
    ./samba.nix
    ./teamspeak3.nix
  ];
}
