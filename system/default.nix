# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./backup.nix
    ./do-init
    ./fonts.nix
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
  boot.kernel.sysctl."vm.swappiness" = pkgs.lib.mkDefault 5;
  environment.sessionVariables.TERMINFO = pkgs.lib.mkDefault "/run/current-system/sw/share/terminfo"; # TODO: the fish bug that needed this may now be fixed, should test
  services.locate.enable = false;
  services.logind.extraConfig = ''
    KillUserProcesses=no
  '';
}
