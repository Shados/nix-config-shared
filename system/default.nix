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
    # Global ssh_config Host definitions
    ./ssh-globalhosts.nix
    ./updatedb.nix
    ./users.nix
  ];
}
