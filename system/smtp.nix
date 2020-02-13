{ config, lib, pkgs, ... }:
with lib;
{
  services.ssmtp = {
    enable = true;
    authPassFile = "/etc/nixos/private-keys/fastmail-smtp.pass";
    authUser = "shados@f-m.fm";
    hostName = "smtp.fastmail.com:465";
    useTLS = true; useSTARTTLS = false;

    domain = "shados.net";
    root = "sn-cronjobs@shados.net";
  };
}
