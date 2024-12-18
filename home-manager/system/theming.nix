{ config, lib, pkgs, ... }:
with lib;
{
  config = mkIf (config.sn.os == "nixos") {
    # TODO declarative config of qt and gtk both?
    # TODO use Fish universal variable support to propagate live variable changes?
    home.sessionVariables = {
      # QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      DESKTOP_SESSION = "gnome";
    };
    home.packages = with pkgs; [
      # TODO investigate if these can safely be user packages while having
      # mis-matched qt system things? Or just move all QT stuff to home-manager?
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      zafiro-icons
    ];
  };
}
