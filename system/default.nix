# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./backup.nix
    ./distributed-home.nix
    ./haveged.nix
    ./kernel.nix
    ./networking.nix
    ./readahead.nix
    ./sound.nix
    ./ssh.nix
    # Global ssh_config Host definitions
    ./ssh-globalhosts.nix
    ./updatedb.nix
    ./users.nix
  ];
}
