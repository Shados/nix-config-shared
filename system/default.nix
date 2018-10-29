# System configuration changes
{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./backup.nix
    ./config-snapshot.nix
    ./do-init
    ./fonts.nix
    ./graphical.nix
    ./haveged.nix
    ./memory.nix
    ./networking.nix
    ./nix.nix
    ./smtp.nix
    ./sound.nix
    ./ssh.nix
    # Global ssh_config Host definitions
    ./ssh-globalhosts.nix
    ./users.nix
  ];

  boot.kernelParams = mkIf (! config.fragments.remote) [ "boot.shell_on_fail" ];
  environment.sessionVariables.TERMINFO = pkgs.lib.mkDefault "/run/current-system/sw/share/terminfo"; # TODO: the fish bug that needed this may now be fixed, should test
  services.locate.enable = false;
  services.logind.extraConfig = ''
    KillUserProcesses=no
  '';
}
