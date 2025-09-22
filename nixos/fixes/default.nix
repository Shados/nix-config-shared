{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge singleton;
in
{
  config = mkMerge [
    (mkIf config.services.mullvad-vpn.enable {
      # Don't default to debug logging, and don't log to file, just use journald
      systemd.services.mullvad-daemon.serviceConfig.ExecStart = lib.mkForce "${config.services.mullvad-vpn.package}/bin/mullvad-daemon --disable-log-to-file --disable-stdout-timestamps";
      systemd.services.mullvad-daemon.environment.TALPID_NET_CLS_MOUNT_DIR = "/run/mullvad-net-cls-v1";
      systemd.services.mullvad-early-boot-blocking = rec {
        description = "Mullvad early boot network blocker";
        unitConfig.DefaultDependencies = "no";
        wants = [ "network-pre.target" ];
        wantedBy = [ "mullvad-daemon.service" ];
        before = wants ++ wantedBy;
        serviceConfig = {
          ExecStart = "${lib.getExe' config.services.mullvad-vpn.package "mullvad-daemon"} --initialize-early-boot-firewall";
          Type = "oneshot";
        };
      };
    })
    {
      systemd.services.rpc-statd-notify.preStart = ''
        mkdir -p /var/lib/nfs/{sm,sm.bak}
      '';
    }
    {
      # Testing workaround for nixpkgs issue #375376
      systemd.package = pkgs.systemd.overrideAttrs(oa: {
        patches = oa.patches or [] ++ [
          ./systemd-fstab-generator-timeout.patch
        ];
      });
    }
  ];
}
