{ config, pkgs, lib, ... }:

with lib;
let 
  cfg = config.fragments.readahead;
in

{
  # TODO: Add actual readahead support to NixOS
  # TODO?: Also maybe add support for using arbitrary .service files from systemd & other packages...

  options.fragments.readahead = {
      enable = mkOption {
        description = ''
          Whether or not to enable systemd's readhaed implementation.
        '';
        default = false;
        type = types.bool;
      };
  };

  config = mkIf cfg.enable {
    systemd.services = { 
      systemd-readahead-collect = { 
        enable = true;
        unitConfig = {
          Description = "Collect Read-Ahead Data";
          Documentation = "man:systemd-readahead-replay.service(8)";
          DefaultDependencies = "no";
          Wants = [ "systemd-readahead-done.timer" ];
          Conflicts = [ "shutdown.target" ];
          Before = [ "sysinit.target" "shutdown.target" ];
          ConditionPathExists = [ "!/run/systemd/readahead/cancel" "!/run/systemd/readahead/done" ];
          ConditionVirtualization = "no";
        };
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-readahead collect";
          RemainAfterExit = "yes";
          StandardOutput = "null";
          OOMScoreAdjust = "1000";
        };
        wantedBy = [ "default.target" ];
      };
      systemd-readahead-drop = {
        enable = true;
        unitConfig = {
          Description = "Drop Read-Ahead Data";
          Documentation = "man:systemd-readahead-replay.service(8)";
          ConditionPathExists = [ "/.readahead" ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/rm -f /.readahead";
        };
        wantedBy = [ "system-update.target" ];
      };
      systemd-readahead-replay = {
        enable = true;
        unitConfig = {
          Description = "Replay Read-Ahead Data";
          Documentation = "man:systemd-readahead-replay.service(8)";
          DefaultDependencies = "no";
          Conflicts = [ "shutdown.target" ];
          Before = [ "sysinit.target" "shutdown.target" ];
          ConditionPathExists = [ "!/run/systemd/readahead/noreplay" "/.readahead" ];
          ConditionVirtualization = "no";
        };
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-readahead replay";
          RemainAfterExit = "yes";
          StandardOutput = "null";
          OOMScoreAdjust = "1000";
        };
        wantedBy = [ "default.target" ];
      };
      systemd-readahead-done = {
        enable = true;
        unitConfig = {
          Description = "Stop Read-Ahead Data Collection";
          Documentation = "man:systemd-readahead-replay.service(8)";
          DefaultDependencies = "no";
          Conflicts = [ "shutdown.target" ];
          After = [ "default.target" ];
          Before = [ "shutdown.target" ];
          ConditionVirtualization = "no";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemd-notify --readahead=done";
        };
      };
    };
    systemd.timers = { 
      systemd-readahead-done = { 
        enable = true;
        unitConfig = {
          Description = "Stop Read-Ahead Data Collection 10s After Completed Startup";
          Documentation = "man:systemd-readahead-replay.service(8)";
          DefaultDependencies = "no";
          Conflicts = [ "shutdown.target" ];
          After = [ "default.target" ];
          Before = [ "shutdown.target" ];
          ConditionVirtualization = "no";
        };
        timerConfig = {
          OnActiveSec = "30s";
          AccuracySec = "1s";
        };
      };
    };
  };
}
