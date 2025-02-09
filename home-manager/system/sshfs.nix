{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.fuse.sshfs;
  escapeSystemdName = s:
    replaceStrings
      [ "/" " " ]
      [ "-" "-" ]
    (if hasPrefix "/" s then substring 1 (stringLength s) s else s);
  # escapeSystemdName = replaceStrings
  #   [ "/" "-"    " "     "+"     "="      ]
  #   [ "-" "\\x2d" "\\x20" "\\x2b" "\\x3d" ];
  # escapeSystemdPath = s:
  #  replaceStrings ["/" "-" " "] ["-" "\\x2d" "\\x20"]
  #   (if hasPrefix "/" s then substring 1 (stringLength s) s else s);
in
{
  options = {
    fuse.sshfs = {
      enable = mkEnableOption "SSHFS mounts";
      mounts = mkOption {
        default = {};
        description = ''
        '';
        type = types.attrsOf (types.submodule ({ config, ... }: {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether or not this mount service should start by default.
              '';
            };

            mountPath = mkOption {
              type = types.str;
              default = config._module.args.name;
              description = ''
                Path on the local machine to mount at.
              '';
            };

            path = mkOption {
              type = types.str;
              default = null;
              description = ''
                Path on the remote machine to mount from.
              '';
            };
            host = mkOption {
              type = types.str;
              default = null;
              description = ''
                SSH host machine to mount from.
              '';
            };
            user = mkOption {
              type = types.str;
              default = null;
              description = ''
                User to SSH into the target machine as.
              '';
            };
          };
        }));
      };
    };
  };
  config = mkIf cfg.enable {
    # FIXME: Implement and depend on a user-level network-online.target, if
    # we're using NetworkManager at the system level and can thus use nm-online
    # to trvially implement it
    systemd.user.services = flip mapAttrs' cfg.mounts (_:  opts: nameValuePair
      "sshfs-${escapeSystemdName opts.mountPath}"
      {
        Unit = {
          Description = "SSHFS auto-mounter service";
          StartLimitIntervalSec = 0;
          # Avoid killing active, possibly-in-use filesystems
          X-RestartIfChanged = false;
        };
        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${opts.mountPath}";
          ExecStart = "${pkgs.sshfs}/bin/sshfs -f -o follow_symlinks,auto_unmount,reconnect,ServerAliveInterval=14 ${opts.user}@${opts.host}:${opts.path} ${opts.mountPath}";
          ExecStop = let
            umount-sshfs = pkgs.writers.writeBash "umount-sshfs" ''
              if command -v "fusermount"; then
                fusermount -u "$1"
              elif command -v "umount"; then
                umount "$1"
              else; then
                exit 1
              fi
            '';
          in "${umount-sshfs} ${opts.mountPath}";
          Restart = "on-failure";
          RestartSec = 1;
          Environment = [
            "PATH=${config.lib.sn.makePath config.lib.sn.baseUserPath}"
          ];
        };
        Install = {
          WantedBy = optional opts.enabled "default.target";
        };
      }
    );
    home.packages = with pkgs; [
      sshfs
    ];
  };
}
