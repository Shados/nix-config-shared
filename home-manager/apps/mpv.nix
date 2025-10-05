{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.mpv = {
    bindings = {
      b = "playlist-shuffle";
      l = ''cycle-values loop-file yes no ; show-text "''${?=loop-file==yes:Looping enabled (file)}''${?=loop-file==no:Looping disabled (file)}"'';
      L = ''cycle-values loop-playlist yes no; show-text "''${?=loop-playlist==inf:Looping enabled}''${?=loop-playlist==no:Looping disabled}"'';
      M = ''af toggle "lavfi=[pan=1c|c0=1*c0+1*c1]" ; show-text "Audio mix set to Mono"'';
      "CTRL+l" = "ab-loop";
    };
    config = {
      stream-buffer-size = "4MiB";
      hwdec = "auto-safe";
      replaygain = "track";
    };
  };
}
