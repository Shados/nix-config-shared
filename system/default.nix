# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./backup.nix
    ./distributed-home.nix
    ./haveged.nix
    ./kernel
    ./networking.nix
    ./sound.nix
    ./ssh.nix
    # Global ssh_config Host definitions
    ./ssh-globalhosts.nix
    ./users.nix
  ];

  boot.kernelParams = [ "boot.shell_on_fail" ];
  services.locate.enable = false;
}
