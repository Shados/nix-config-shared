{ config, pkgs, lib, ... }:
{
  imports = [
    ./module.nix
  ];

  services.openssh = {
    enable = true;
    # Some options for improved security
    # Non-default to reduce drive-by SSH attacks, SSH module automatically adds its ports to the FW
    ports = [ 54201 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      LogLevel = "VERBOSE";
    };
    extraConfig = ''

      # Supporting URXVT-256color and other non-standard terms a bit better
      AcceptEnv TERMINFO

      # Use within-SSH keepalives; helps to quickly reap failed ssh
      # connections and is useful for long-living, auto-restarting SSH
      # tunnels
      # Send 8 seconds, 3 sequential failures == dead connection
      ClientAliveInterval 8
      ClientAliveCountMax 3
    '';
  };

  programs.ssh.knownHosts = {
    "git.shados.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO0oGzy9ylQHKEYaH4jJ38QM9nFxiQTF+flQUYbpqbF6";
  };
  programs.ssh.globalHosts = {
    # Host entry for the SN NixOS configuration remote git repo
    gitolite = {
      hostName = "git.shados.net";
      user = "gitolite";
      port = 54201;
      keyFile = "/etc/nixos/private-keys/nixos-config@shados.net.id_ecdsa";
    };
  };

  security.pam.enableSSHAgentAuth = true;
}
