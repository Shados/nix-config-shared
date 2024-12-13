{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.networking.wireguard;
  wgInts = attrNames cfg.interfaces;
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
        Restart = mkDefault "always";
        RestartSec = mkDefault 3;
        Type = mkForce "simple";
      };
    };
  # NOTE: Taken from nixpkgs module, wish this were exposed somehow as it is
  # slightly involved
  wgAllPeers = flatten
    (mapAttrsToList (interfaceName: interfaceCfg:
      map (peer: { inherit interfaceName interfaceCfg peer;}) interfaceCfg.peers
    ) cfg.interfaces);
  mkPeerServiceName = interfaceName: peer: "wireguard-${interfaceName}-peer-${peer.name}";
in
{
  config = mkMerge [
    # FIXME Workaround for issue detailed in https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1595743529
    # Sadly, this is quite a hack, and mostly defeats the purpose of
    # network-online.target, but I cannot find a better workaround or fix
    # currently. Probably need to talk to the NM devs.
    (mkIf config.networking.networkmanager.enable {
      systemd.services.NetworkManager-wait-online = {
        serviceConfig = {
          ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
          Restart = "on-failure";
          RestartSec = 1;
        };
        unitConfig.StartLimitIntervalSec = 0;
      };
    })
    {
      systemd.services = listToAttrs (map (modifyWgService) wgInts);
    }
    { # FIXME: Workaround for issue detailed in https://github.com/NixOS/nixpkgs/issues/63869#issuecomment-514655131
      systemd.services = listToAttrs (map ({ interfaceName, interfaceCfg, peer }: nameValuePair
        (mkPeerServiceName interfaceName peer)
        {
          serviceConfig = {
            Restart = mkDefault "on-failure";
            RestartSec = mkDefault 3;
            Type = mkForce "simple";
          };
        }
      ) wgAllPeers);
    }
  ];
}
