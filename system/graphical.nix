{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments.graphical;
  ucfg = config.fragments.graphical.urxvt;
  gnome_cfg = config.services.xserver.desktopManager.gnome3;

  GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-libav ];

  default_xresources_colors = builtins.readFile ./xresources/default;

  baseline_xresources = ''
    ! Shados-made custom settings:
    ! XTerm settings
    !xterm*faceName: Anka/Coder:size=8:antialias=false
    xterm*faceName: xft:FantasqueSansMono Nerd Font:style=Regular:size=10:antialias=true

    ! URxvt settings
    URxvt.intensityStyles: false
    ! URxvt.font: xft:Anka/Coder:size=8:antialias=true
    URxvt.font: xft:${ucfg.font}:size=${toString ucfg.fontSize}:antialias=true
    URxvt.scrollBar: false
    URxvt.perl-ext-common: ${concatStringsSep "," ucfg.plugins}
    ! URxvt.url-launcher: /home/shados/technotheca/artifacts/packages/bin/ff-link
    URxvt.matcher.button: 1
    URxvt.colorUL: S_blue
    URxvt.fading: 10
    URxvt.iso14755: False

    ! General font settings
    Xft.autohint: 0
    Xft.lcdfilter: lcddefault
    Xft.hintstyle: hintslight
    Xft.hinting: 1
    Xft.antialias: 1
    Xft.rgba: rgb
  '';

  default_xresources = pkgs.writeText "XResources" ''
    ${baseline_xresources}

    ${default_xresources_colors}
  '';

  nixos-gsettings-desktop-schemas = pkgs.runCommand "nixos-gsettings-desktop-schemas" {} # {{{
    ''
     mkdir -p $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas
     cp -rf ${pkgs.gnome3.gsettings_desktop_schemas}/share/gsettings-schemas/gsettings-desktop-schemas*/glib-2.0/schemas/*.xml $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

     ${concatMapStrings (pkg: "cp -rf ${pkg}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas\n") gnome_cfg.extraGSettingsOverridePackages}

     chmod -R a+w $out/share/gsettings-schemas/nixos-gsettings-overrides
     cat - > $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas/nixos-defaults.gschema.override <<- EOF
       [org.gnome.desktop.background]
       picture-uri='${pkgs.nixos-artwork.wallpapers.gnome-dark}/share/artwork/gnome/Gnome_Dark.png'

       [org.gnome.desktop.screensaver]
       picture-uri='${pkgs.nixos-artwork.wallpapers.gnome-dark}/share/artwork/gnome/Gnome_Dark.png'

       ${gnome_cfg.extraGSettingsOverrides}
     EOF

     ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas/
    ''; # }}}
in

{
  options = {
    fragments.graphical = {
      enable = mkEnableOption "graphical environment / UI support";


      urxvt = {
        font = mkOption {
          type = with types; str;
          default = "FantasqueSansMono Nerd Font:style=Regular";
          description = ''
            XFT font name for urxvt to use.
          '';
        };
        fontSize = mkOption {
          type = with types; int;
          default = 10;
          description = ''
            XFT font size to use for urxvt.
          '';
        };
        plugins = mkOption {
          type = with types; listOf str;
          default = [ "default" "config-reload" ];
          description = ''
            List of urxvt perl plugin/extension names to enable.
          '';
          example = [ "default" "color-themes" ];
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Baseline desktop (X11) setup {{{
    {
      environment.pathsToLink = [
        "/etc/xdg"
        # Needed for themes and backgrounds
        "/share/"
      ];
      services = {
        xserver = {
          enable = true;

          desktopManager.xterm.enable = false;
          desktopManager.default = "shadosnet";

          desktopManager.session = [ # {{{
            { name = "shadosnet";
              start = ''
                # Set GTK_DATA_PREFIX so that GTK+ can find the themes
                export GTK_DATA_PREFIX=/run/current-system/sw/:~/.local/share/themes

                # Find theme engines
                export GTK_PATH=/run/current-system/sw/lib/gtk-3.0:/run/current-system/sw/lib/gtk-2.0

                # Find mouse icons
                export XCURSOR_PATH=~/.icons:/run/current-system/sw/share/icons

                export GST_PLUGIN_PATH="${GST_PLUGIN_PATH}"

                # Override default mimeapps
                export XDG_DATA_DIRS=$XDG_DATA_DIRS''${XDG_DATA_DIRS:+:}:/run/current-system/sw/share

                # Override gsettings-desktop-schema
                export NIX_GSETTINGS_OVERRIDES_DIR=${nixos-gsettings-desktop-schemas}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

                # Update user dirs as described in http://freedesktop.org/wiki/Software/xdg-user-dirs/
                ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update

                # Custom Xresources setup
                ${pkgs.xorg.xrdb}/bin/xrdb -merge ${default_xresources}

                ${pkgs.openbox}/bin/openbox-session
              '';
            }
          ]; # }}}

          #windowManager.openbox.enable = true;
          #windowManager.default = "openbox";

          displayManager.slim.enable = true;

          updateDbusEnvironment = true;
        };
      };
      environment.variables.GIO_EXTRA_MODULES = [
        "${lib.getLib pkgs.gnome3.dconf}/lib/gio/modules"
        "${pkgs.gnome3.glib_networking.out}/lib/gio/modules"
        "${pkgs.gnome3.gvfs}/lib/gio/modules"
      ];
      environment.systemPackages = with pkgs; with pkgs.xlibs; [
        openbox

        xmodmap

        # Baseline themes / theme engines
        tango-icon-theme
        hicolor_icon_theme
        gnome2.gnome_icon_theme
        oxygen
        gnome2.gtk
        gtk_engines
        gtk-engine-murrine
        gnome3.gnome_themes_standard
        gnome3.adwaita-icon-theme

        arc-theme
        arc-icon-theme

        glxinfo
        lxappearance
        obconf
      ];
      # Convenient `/etc` symlink so I can easily reload from my defaults
      environment.etc.default_xresources.source = default_xresources;
      nixpkgs.config.packageOverrides = pkgs: with pkgs; {
        # qt48 = pkgs.qt48.override { gtkStyle = true; };
        # qt55 = pkgs.qt55.override { gtkStyle = true; };
        # qt56 = pkgs.qt56.override { gtkStyle = true; };
      };
    }
    # Browser stuff {{{
    {
      # Avoiding using an actual derivation ref, as I may not be using the
      # standard firefox on every box
      services.nixosManual.browser = "/run/current-system/sw/bin/firefox";
    }
    # }}}
    # }}}
    # urxvt setup {{{
    {
      environment.systemPackages = with pkgs; [
        rxvt_unicode-with-plugins
      ];
    }
    # }}}
  ]);
}
