{ config, lib, pkgs, ... }:
with lib;
{
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      host = "smtp.fastmail.com";
      port = 465;
      user = "shados@f-m.fm";
      passwordeval = "cat /etc/nixos/private-keys/fastmail-smtp.pass";
      tls = true;
      tls_starttls = false;
      from = "cronjobs@shados.net";
      set_from_header = true;
    };
    defaults = {
      domain = "shados.net";
    };
  };
}
