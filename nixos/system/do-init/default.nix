{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sn.digitalocean;

  do-init = with pkgs; callPackage ./digitalocean-init.nix {};
in

{
  options = {
    sn.digitalocean = {
      enable = mkEnableOption "DigitalOcean support";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ do-init ]; # For manual debugging

    networking.useDHCP = false;

    systemd.services.digitalocean-init = {
      requiredBy = [ "multi-user.target" ];
      # wantedBy = [ "network.target" ];
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        #ExecStart = pkgs.writeScript "digitalocean-init" (builtins.readFile ./digitalocean-init);
        ExecStart = "${do-init}/bin/digitalocean-init";
      };
    };
  };
}
