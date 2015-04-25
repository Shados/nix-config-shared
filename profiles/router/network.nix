{ config, pkgs, lib, ... }:

let 
  cfg = config.fragments.router;
in

lib.mkIf (config.fragments.router.enable) {
  networking = {
    # Set up the bridge
    bridges.${cfg.intBridge}.interfaces = cfg.intInts;
    interfaces.${cfg.intBridge} = {
      ipAddress = cfg.intSubnet + ".1";
      prefixLength = 24;
    };

    # NAT setup
    nat = {
      #enable = true; # TODO: Re-enable once sn-firewall.nix is upstream'd
      externalInterface = cfg.extInt;
      internalIPs = [ "${cfg.intSubnet + ".0/24"}" ];
    };
  };
}
