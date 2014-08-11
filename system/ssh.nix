{ config, pkgs, ... }:

with pkgs.lib;

let
  cfg = config.services.openssh;
in

{
  options.services.openssh = {
    allowed_users = mkOption {
      description = ''
        A list of the users allowed to log in via SSH.
      '';
      default = [ "shados" ];
      type = types.nullOr (types.listOf types.str);
    };
  };

  config = {
    services.openssh = {
      enable = true;
      # Some options for improved security
      ports = [ 54201 ]; # Non-default port for security, SSH module automatically adds its ports to the FW
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      permitRootLogin = "no";
      extraConfig = 
        ''
          AllowUsers ${concatMapStrings (user: ''${user} '') cfg.allowed_users}
        '';
    };
    # Add Mosh & allow Mosh ports :)
    environment.systemPackages = [ pkgs.mosh ];
    networking.firewall.allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];
  };
}
