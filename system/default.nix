# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./backup.nix
    ./distributed-home.nix
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
  environment.sessionVariables.TERMINFO = pkgs.lib.mkDefault "/run/current-system/sw/share/terminfo"; # TODO: Remove once fish upstream bug is fixed
  services.locate.enable = false;
  services.logind.extraConfig = ''
    KillUserProcesses=no
  '';
}
