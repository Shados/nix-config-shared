{ config, pkgs, lib, ... }:
{
  imports = [
    ./module.nix
    ./ssh-globalhosts.nix
  ];

  config = {
    services.openssh = {
      enable = true;
      # Some options for improved security
      ports = [ 54201 ]; # Non-default port for security, SSH module automatically adds its ports to the FW
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      permitRootLogin = "no";
      extraConfig = ''
        LogLevel VERBOSE

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

    # Allow X11 forwarding by default, useful for porting remote clipboard to local
    # Also needs ForwardX11 and ForwardX11Trusted set on the client side for this host
    services.openssh.forwardX11 = true;
  };
}
