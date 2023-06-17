{ config, lib, pkgs, ... }:
# TODO actual config 
with lib;
let
  mpdCfg = config.services.mpd;
  cfg = config.services.mpdscribble;
in
{
  options = {
    services.mpdscribble = {
      enable = mkEnableOption "MPDScribble Last.fm scrobbler for MPD";
    };
  };

  config = mkIf (mpdCfg.enable && cfg.enable) {
    systemd.user.services = {
      mpdscribble = {
        Unit = {
          Description = "MPD Scrobbler";
          Requires = [ "mpd.service " ];
          After = [ "mpd.service " ];
        };
        Install = {
          Wantedby = [ "default.target" ];
        };
        Service = {
          ExecStart = "${pkgs.mpdscribble}/bin/mpdscribble --no-daemon --conf %h/.config/mpdscribble/mpdscribble.conf";
          # TODO: config
        };
      };
    };
  };
}
