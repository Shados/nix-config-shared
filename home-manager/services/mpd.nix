{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mpd;
in
{
  config = mkIf cfg.enable {
    services.mpd.extraConfig = ''
      # Fuck avahi
      zeroconf_enabled		"no"

      # Web radio/streaming support
      input {
        plugin "curl"
      }

      # Pulseaudio compatibility
      audio_output {
        type "pulse"
        name "MPD Output"
        mixer_type "software"
      }
    '';
    systemd.user.services.mpd = {
      Unit = {
        After = [ "pulseaudio.service" ]; # TODO depend on PA being enabled?
      };
      Service = {
        Restart = "on-abnormal";
        # Allow MPD to use real-time priority 50
        LimitRTPRIO = 50;
      };
    };
  };
}
