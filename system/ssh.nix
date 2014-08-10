{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    # Some options for improved security
    ports = [ 54201 ]; # Non-default port for security, SSH module automatically adds its ports to the FW
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    permitRootLogin = "no";
    extraConfig = 
      ''
        AllowUsers shados
      '';
  };
  # Add Mosh & allow Mosh ports :)
  environment.systemPackages = [ pkgs.mosh ];
  networking.firewall.allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];
}
