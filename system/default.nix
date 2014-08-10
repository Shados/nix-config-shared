# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./distributed-home.nix
    ./haveged.nix
    ./kernel.nix
    ./readahead.nix
    ./sound.nix
    ./ssh.nix
    ./updatedb.nix
    ./users.nix
  ];
}
