{ config, pkgs, ... }:
{
  # 'locate' search indexing update
  # Disabling the service actually only removes the line starting it from /etc/crontab, which is good as we're using systemd timers to start it instead
  services.locate.enable = false;
  #TODO: More or less copied from https://github.com/NixOS/nixpkgs/pull/2758 - should be removed once that is finished + merged
  systemd.timers.update-locatedb = {
    description = "Trigger Locate database update every 24 hours";
    timerConfig = {
      OnCalendar = "daily"; # Normalized to midnight every day
      AccuracySec = "12h"; # Activate within +12H of the calendar time set, according to when systemd decides is best based on technical considerations
      Persistent = true; # Will trigger when the timer is activated (i.e. at boot) if it missed any activations while the machine was shut down or the timer deactivated
    };
    wantedBy = [ "timers.target" ];
  };
}
