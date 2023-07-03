{ config, lib, pkgs, ... }:
with lib;
{
  sops.secrets.msmtp-password-fastmail.owner = "shados";
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      host = "smtp.fastmail.com";
      port = 465;
      user = "shados@f-m.fm";
      passwordeval = "cat ${config.sops.secrets.msmtp-password-fastmail.path}";
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
