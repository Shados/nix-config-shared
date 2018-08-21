# System configuration changes
{ config, pkgs, ... }:

{
  imports = [
    ./backup.nix
    ./config-snapshot.nix
    ./do-init
    ./fonts.nix
    ./graphical.nix
    ./haveged.nix
    ./networking.nix
    ./sound.nix
    ./ssh.nix
    # Global ssh_config Host definitions
    ./ssh-globalhosts.nix
    ./users.nix
  ];

  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.kernel.sysctl = {
    # I don't know why the hell NixOS defaults this to 50? Or maybe it's the kernel default..?
    "vm.overcommit_ratio" = pkgs.lib.mkDefault 100;
    # Default to max overcommit of (swap + (real_ram * overcommit_ratio)), in
    # this instance meaning do not allow committing more memory than is
    # actually available. Prevents the OOM killer from ever being invoked, but
    # does mean malloc() may fail. Of course, to a *well-written* program,
    # malloc() failing is not the worst thing that can happen.
    "vm.overcommit_memory" = 2;
    # Most of my systems have plenty of RAM, so default to less swappy.
    "vm.swappiness" = pkgs.lib.mkDefault 5;
  };
  environment.sessionVariables.TERMINFO = pkgs.lib.mkDefault "/run/current-system/sw/share/terminfo"; # TODO: the fish bug that needed this may now be fixed, should test
  services.locate.enable = false;
  services.logind.extraConfig = ''
    KillUserProcesses=no
  '';
}
