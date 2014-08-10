{ config, pkgs, ... }:

pkgs.lib.mkIf (config.fragments.router.enable) {
  networking.sn-firewall.enable = true;
  networking.sn-firewall.enable_nat = true;

  # Because I'm planning on merging sn-firewall back upstream as the default firewall, and because I want transparent compatibility, we just read the existing firewall settings :)
  networking.firewall = { 
    allowPing = true;
    checkReversePath = false; # RP filtering on the bridge breaks broadcast packets due to reasons - TODO: Figure out why. TODO: Implement custom workaround.
    extraCommands = ''
      # Setup custom chains
      -N lan-fw
    '';
  };

}

# TODO: Upstream sn-firewall implementation
#   - TODO: Deal with things like libvirt that add iptables rules of their own
#   - TODO: Deal with adding custom rules to non-'filter' tables
#   - 
#   - 
