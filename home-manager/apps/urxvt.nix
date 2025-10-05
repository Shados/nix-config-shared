{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.urxvt = {
    scroll.bar.enable = false;
    iso14755 = false;
    extraConfig = {
      # Allows skipping the rendering of text that wouldn't actually be
      # displayed *between* frames. This does mean that some text is never
      # shown (unless you scroll back), but it also means that the
      # terminal/refresh rate don't bottleneck output on a command.
      skipScroll = true;
      fading = 5;
      intensityStyles = false;
    };
  };
}
