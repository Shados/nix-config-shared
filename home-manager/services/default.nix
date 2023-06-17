{ config, lib, pkgs, ... }:
{
  imports = [
    ./darwin-crontab-module.nix
    ./mpd.nix
    ./mpdscribble.nix
    ./pipewire.nix
    ./syncthing
    ./urxvt.nix
    ./wired-notify.nix
  ];
}
