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
        Restart = mkDefault "always";
        RestartSec = mkDefault 3;
        Type = mkForce "simple";
      };
    };
in
{
  config = mkMerge [
    {
      systemd.services = listToAttrs (map (modifyWgService) wgInts);
    }
    { # Workaround for issue detailed in https://github.com/NixOS/nixpkgs/issues/63869#issuecomment-514655131
      systemd.services = let
        allPeers = flatten (mapAttrsToList (n: cfg:
          map (peer: { intName = n; inherit peer; }) cfg.peers
        ) config.networking.wireguard.interfaces);
        keyToUnitName = replaceChars
          [ "/" "-"    " "     "+"     "="      ]
          [ "-" "\\x2d" "\\x20" "\\x2b" "\\x3d" ];
      in listToAttrs (map ({ intName, peer }: nameValuePair
        "wireguard-${intName}-peer-${keyToUnitName peer.publicKey}"
        {
          serviceConfig = {
            Restart = mkDefault "on-failure";
            RestartSec = mkDefault 3;
            Type = mkForce "simple";
          };
        }
      ) allPeers);
    }
  ];
}
