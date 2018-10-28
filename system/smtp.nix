{ config, lib, pkgs, ... }:
with lib;
{
  networking.defaultMailServer = {
    authPassFile = "/etc/nixos/private-keys/fastmail-smtp.pass";
    authUser = "shados@f-m.fm";
    directDelivery = true;
    hostName = "smtp.fastmail.com:465";
    useTLS = true; useSTARTTLS = false;

    domain = "shados.net";
    root = "sn-cronjobs@shados.net";
  };
}
