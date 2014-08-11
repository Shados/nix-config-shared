{ config, pkgs, ... }:

{
  programs.ssh.globalHosts = {
    # Host entry for the SN NixOS configuration remote git repo
    gitolite = {
      hostName = "sns4.shados.net";
      user = "gitolite";
      port = 54201;
      keyFile = "/etc/nixos/modules/keys/nixos-config@shados.net.id_ecdsa";
    };
  };
}
