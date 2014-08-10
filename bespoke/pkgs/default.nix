{ config, pkgs, ... }:

{
  imports = [
    ./hah
    ./hostapd-git
  ];
}
