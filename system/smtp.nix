{ config, lib, pkgs, ... }:
with lib;
{
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      host = "smtp.fastmail.com:465";
      user = "shados@f-m.fm";
      passwordeval = "cat /etc/nixos/private-keys/fastmail-smtp.pass";
    };
    defaults = {
      tls = true;
      tls_starttls = true;
      domain = "shados.net";
      from = "sn-cronjobs@shados.net";
    };
  };
}
