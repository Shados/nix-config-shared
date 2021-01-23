{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments.graphical;
  gnome_cfg = config.services.xserver.desktopManager.gnome3;

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

  nixos-gsettings-desktop-schemas = pkgs.runCommand "nixos-gsettings-desktop-schemas" {
    preferLocalBuild = true;
  } # {{{
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
      enable = mkEnableOption "graphical environment / UI / user-facing support";
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
        xserver = {
          enable = true;

          displayManager.defaultSession = "xsession+none";
          desktopManager.xterm.enable = false;
          desktopManager.session = singleton {
            name = "xsession";
            start = ''
              ${pkgs.gnome3.zenity}/bin/zenity --error --text "The user must provide a ~/.xsession file containing session startup commands." --no-wrap
            '';
          };

          displayManager.sessionCommands = ''
            # Override gsettings-desktop-schema
            export NIX_GSETTINGS_OVERRIDES_DIR=${nixos-gsettings-desktop-schemas}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

            # Custom Xresources setup
            ${pkgs.xorg.xrdb}/bin/xrdb -merge ${default_xresources}
          '';

          # displayManager.slim.enable = true; # RIP SLIM
          displayManager.sddm = {
            enable = true;
          };

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

        snap

        # Shit needed for gnome apps to work right
        gnome3.dconf gnome3.dconf-editor

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
    # Gnome compat crap
    {
      services = {
        # This is like 70% of what `services.gnome3.core-shell.enable = true;` does
        gvfs.enable = true;
        gnome3.gnome-settings-daemon.enable = true;
        gnome3.glib-networking.enable = false;
      };
      systemd.packages = with pkgs.gnome3; [ gnome-session ];
      xdg.portal.extraPortals = [ pkgs.gnome3.gnome-shell ];
      fonts.fonts = with pkgs; [
        cantarell-fonts
        dejavu_fonts
        source-code-pro # Default monospace font in 3.32
        source-sans-pro
      ];

      # Adapt from https://gitlab.gnome.org/GNOME/gnome-build-meta/blob/gnome-3-32/elements/core/meta-gnome-core-shell.bst
      environment.systemPackages = with pkgs.gnome3; [
        adwaita-icon-theme
        gnome-backgrounds
        gnome-bluetooth
        gnome-color-manager
        gnome-control-center
        gnome-getting-started-docs
        gnome-shell
        gnome-shell-extensions
        gnome-themes-extra
        gnome-user-docs
        pkgs.orca
        pkgs.glib # for gsettings
        pkgs.gnome-menus
        pkgs.gtk3.out # for gtk-launch
        pkgs.hicolor-icon-theme
        pkgs.shared-mime-info # for update-mime-database
        pkgs.xdg-user-dirs # Update user dirs as described in http://freedesktop.org/wiki/Software/xdg-user-dirs/
      ];
    }
    # }}}

    # Latency-oriented tweaking
    {
      boot.kernel.sysctl = {
        # CPU scheduling tweaks (CFS) {{{
        # Minimum timeslice per task before they can be preempted if required.
        "kernel.sched_min_granularity_ns" = 500000; # 0.5ms, from 3,000,000 / 3ms

        # Minimum timeslice allotted to a task woken by an event/interrupt.
        "kernel.sched_wakeup_granularity_ns" = 500000; # 0.5ms, from 4,000,000 / 4ms

        # Period within which each task is guaranteed to be scheduled at least
        # once. If (number_of_tasks * sched_min_granularity_ns) >
        # sched_latency_ns, then sched_latency_ns will equal number_of_tasks *
        # sched_min_granularity_ns instead.
        "kernel.sched_latency_ns" = 4000000; # 4ms, from 24,000,000 / 24ms
        # }}}
      };
    }
  ]);
}
