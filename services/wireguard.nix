{ config, lib, pkgs, ... }:

with lib;
let
  wgInts = attrNames config.networking.wireguard.interfaces;
  modifyWgService = wgInt: nameValuePair
    "wireguard-${wgInt}"
    {
      # This can't be done in wireguard's per-int 'preSetup', for some reason.
      # Haven't looked into it very hard.
      preStart = ''
        # Work around a kind of race condition and ensure the link is actually
        # deleted before attempting to re-add it
        ip link delete dev ${wgInt} || { true; }
      '';
      # Improve the behaviour on transient failures
      serviceConfig = {
        Restart = mkDefault "on-abnormal";
        RestartSec = mkDefault 3;
        Type = mkForce "simple";
      };
    };
in
{
  systemd.services = listToAttrs (map (modifyWgService) wgInts);
}
