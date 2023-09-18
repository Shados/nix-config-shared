{ config, pkgs, lib, ... }:
# FIXME: Go through nixpkgs/nixos/modules/services/x11/desktop-managers/xfce.nix in detail and codge things
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

          displayManager.defaultSession = "xsession";
          desktopManager.xterm.enable = false;
          desktopManager.session = singleton {
            name = "xsession";
            start = ''
              ${pkgs.gnome3.zenity}/bin/zenity --error --text "The user must provide a ~/.xsession file containing session startup commands." --no-wrap
            '';
          };

          displayManager.sessionCommands = ''
            # Custom Xresources setup
            ${pkgs.xorg.xrdb}/bin/xrdb -merge ${default_xresources}
          '';

          # displayManager.slim.enable = true; # RIP SLIM
          displayManager.sddm = {
            enable = true;
          };

          updateDbusEnvironment = true;
          # Necessary for GTK to support SVG. GTK uses SVG icons by default in
          # many ways. Yes, not being able to support its own default icon
          # format without an external run-time dependency *is* somewhat
          # insane.
          gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
        };
      };
      xdg = {
        autostart.enable = true;
        icons.enable = true;
        menus.enable = true;
        mime.enable = true;
        sounds.enable = true;
        portal.enable = true;
        portal.extraPortals = [
          pkgs.xdg-desktop-portal-xapp
          (pkgs.xdg-desktop-portal-gtk.override {
            # Do not build portals that we already have.
            buildPortalsInGnome = false;
          })
        ];
      };
      environment.systemPackages = with pkgs; with pkgs.xorg; [
        xmodmap

        # Baseline themes / theme engines
        tango-icon-theme
        hicolor-icon-theme
        gnome2.gnome_icon_theme
        oxygen
        gnome2.gtk
        gtk_engines
        gtk-engine-murrine
        gnome.gnome-themes-extra
        gnome3.adwaita-icon-theme

        arc-theme
        arc-icon-theme

        glxinfo
        lxappearance

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
            lcdfilter = mkDefault "light";
            rgba = mkDefault "rgb";
          };
        };
      };
    }
    # GSettings stuff, hahhh
    {
      programs.dconf.enable = true;
      environment.systemPackages = with pkgs; [
        glib # for gsettings itself
        gsettings-desktop-schemas
      ];
      environment.sessionVariables.XDG_DATA_DIRS = let
        schema = pkgs.gsettings-desktop-schemas;
      in singleton "${schema}/share/gsettings-schemas/${schema.name}";
    }
    # Further Gnome compat crap
    {
      services = {
        # This is like 70% of what `services.gnome3.core-shell.enable = true;` does
        gvfs.enable = true;
        gnome.gnome-settings-daemon.enable = true;
        gnome.glib-networking.enable = false;
      };
      systemd.packages = with pkgs.gnome3; [ gnome-session ];
      fonts.fonts = with pkgs; [
        cantarell-fonts
        dejavu_fonts
        source-code-pro # Default monospace font in 3.32
        source-sans-pro
      ];

      # Adapt from https://gitlab.gnome.org/GNOME/gnome-build-meta/blob/gnome-3-32/elements/core/meta-gnome-core-shell.bst
      environment.systemPackages = with pkgs.gnome3; [
        adwaita-icon-theme
        gnome-themes-extra
        pkgs.gnome-menus
        pkgs.gtk3 # for gtk-launch
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
