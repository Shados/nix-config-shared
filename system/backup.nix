{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sn.backup;
in

{
  options = {
    sn.backup = {
      folders = mkOption {
        description = ''
          A list of the folders that should be readable by the backup user.
        '';
        default = [];
        type = types.nullOr (types.listOf types.path);
      };
      enable = mkOption {
        description = ''
          Whether or not to enable backup user support.
        '';
        default = false;
        type = types.bool;
      };
    };
  };

  config = mkIf cfg.enable {
    # Setup rssh, the ReStricted SHell
    environment.systemPackages = with pkgs; [ rssh ];
    environment.etc."rssh.conf".text = ''
      logfacility = LOG_USER

      allowscp
      allowsftp
      allowrsync

      umask = 022
    '';

    # Allow backup account login over ssh
    services.openssh = {
      allowed_users = [ "backup" ];
    };

    # Create backup user
    users.extraUsers.backup = {
      createHome = false;
      home = "/var/empty";
      description = "Backup User";
      uid = 10000;
      openssh.authorizedKeys.keyFiles = [ "/etc/nixos/modules/keys/backup@stowaway.shados.net.id_ecdsa.pub" ];
      passwordFile = "/etc/nixos/modules/passwords/shados";
      shell = "/run/current-system/sw/bin/rssh";
    };
    # Ensure ACLs are set for backup directories so that the backup user can actually read them
    # TODO timer, default daily + optional config
    systemd.services.set_backup_acls = {
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = "${concatStringsSep " " cfg.folders}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = pkgs.writeScript "set_backup_acls.sh" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.utillinux}/bin/ionice -c 3 -p $$
          ${pkgs.utillinux}/bin/renice -n 19 -p $$
          ${pkgs.acl.bin}/bin/setfacl -R -m u:backup:rX ${concatStringsSep " " cfg.folders}
          ${pkgs.acl.bin}/bin/setfacl -R -m d:u:backup:rX ${concatStringsSep " " cfg.folders}
        '';
      };
    };
  };
}
