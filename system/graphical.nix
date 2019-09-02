{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments.graphical;
  gnome_cfg = config.services.xserver.desktopManager.gnome3;

  GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-libav ];

  colors = {
    solarizedDark = builtins.readFile ./xresources/solarized-dark;
    oceanicNext = builtins.readFile ./xresources/oceanic-next;
  };

  baselineXresources = ''
    ! General font settings
    Xft.autohint: 0
    Xft.lcdfilter: lcddefault
    Xft.hintstyle: hintslight
    Xft.hinting: 1
    Xft.antialias: 1
    Xft.rgba: rgb
  '';

  default_xresources = pkgs.writeText "XResources" ''
    ${baselineXresources}

    ${colors.oceanicNext}
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
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Baseline desktop (X11) setup {{{
    {
      fragments.remote = mkDefault false;
      environment.pathsToLink = [
        "/etc/xdg"
        # Needed for themes and backgrounds
        "/share/"
      ];
      security.polkit.enable = true;
      services = {
        accounts-daemon.enable = true;
        udisks2.enable = true;
        upower.enable = true;
        gnome3.core-shell.enable = true;
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

                exec ${pkgs.dbus}/bin/dbus-launch --sh-syntax --exit-with-session ${pkgs.openbox}/bin/openbox-session
              '';
            }
          ]; # }}}

          #windowManager.openbox.enable = true;
          #windowManager.default = "openbox";

          displayManager.slim.enable = true;

          updateDbusEnvironment = true;
        };
      };
      xdg = {
        autostart.enable = true;
        icons.enable = true;
        menus.enable = true;
        mime.enable = true;
        sounds.enable = true;
        portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
          ];
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

        dunst libnotify
        snap

        # Spellchecking dictionary
        hunspellDicts.en-gb-ise
      ];
      nixpkgs.config.packageOverrides = pkgs: with pkgs; {
        # qt48 = pkgs.qt48.override { gtkStyle = true; };
        # qt55 = pkgs.qt55.override { gtkStyle = true; };
        # qt56 = pkgs.qt56.override { gtkStyle = true; };
      };

      # Convenient `/etc` symlink so I can easily reload from my defaults
      environment.etc.default_xresources.source = default_xresources;

      fonts = {
        fontconfig = {
          cache32Bit = true;
          # defaultFonts = {};
          subpixel = {
            lcdfilter = "light";
            rgba = "rgb";
          };
        };
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
  ]);
}
