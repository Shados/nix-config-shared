{ config, pkgs, ... }:

{
  programs.ssh.globalHosts = {
    # Host entry for the SN NixOS configuration remote git repo
    gitolite = {
      hostName = "git.shados.net";
      user = "gitolite";
      port = 54201;
      keyFile = "/etc/nixos/prviate-keys/nixos-config@shados.net.id_ecdsa";
    };
  };
}
