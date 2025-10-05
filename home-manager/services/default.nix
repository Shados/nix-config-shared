{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./darwin-crontab-module.nix
    ./pipewire.nix
    ./syncthing
    ./urxvt.nix
    ./wired-notify.nix
  ];
  systemd.user.startServices = true;
}
